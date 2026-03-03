import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:sigap_mobile/features/pantau/domain/status_pantauan.dart';
import 'package:sigap_mobile/features/pantau/services/pantau_aman_flag.dart';

/// Singleton state machine — satu-satunya authority untuk state Pantau Aku.
///
/// Tanggung jawab:
///   - Mengelola countdown timer (foreground)
///   - Membuka overlay saat check-in
///   - Menangani eskalasi (kesempatan 1→2→3→darurat)
///   - Menerima event dari background service sebagai BACKUP
///   - Menerima sinyal AMAN dari overlay via IPC
class PantauService {
  PantauService._privateConstructor();
  static final PantauService _instance = PantauService._privateConstructor();
  static PantauService get instance => _instance;

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  final _stateController = StreamController<StatusPantauan>.broadcast();
  Stream<StatusPantauan> get stateStream => _stateController.stream;

  StatusPantauan _currentState = const Persiapan();
  StatusPantauan get currentState => _currentState;

  int _intervalDetik = 45 * 60;
  int _kesempatan = 0;

  /// Timer untuk countdown Aktif (display + trigger check-in di foreground).
  Timer? _uiTickTimer;

  /// Timer untuk countdown CheckIn (eskalasi otomatis).
  Timer? _checkinTimer;

  StreamSubscription? _overlaySubscription;
  StreamSubscription? _tickSubscription;
  StreamSubscription? _amanSubscription;
  StreamSubscription? _daruratSubscription;

  void initialize() {
    _listenToBackgroundService();

    _overlaySubscription = FlutterOverlayWindow.overlayListener.listen((data) {
      if (data == 'AMAN' || data == 'AMAN_CONFIRMED') {
        _handleAman();
      }
    });

    _emitState(const Persiapan());
  }

  void _emitState(StatusPantauan newState) {
    _currentState = newState;
    _stateController.add(newState);
  }

  // ══════════════════════════════════════════════════════════════
  // BACKGROUND SERVICE LISTENER (BACKUP — jaga-jaga jika app
  // di-background dan UI timer ter-suspend oleh Android)
  // ══════════════════════════════════════════════════════════════

  void _listenToBackgroundService() {
    final service = FlutterBackgroundService();

    _tickSubscription = service.on('tick').listen((event) {
      if (event == null) return;

      final int bgState = event['state'];
      final int bgSisa = event['seconds'];
      final int bgKesempatan = event['kesempatan'] ?? 0;

      // Guard: jangan izinkan background me-regress state
      if (_currentState is DaruratTerkirim) return;
      if (_currentState is CheckInDiminta && bgState == 1) return;

      switch (bgState) {
        case 1:
          _emitState(Aktif(
            sisaDetik: bgSisa,
            intervalDetik: _intervalDetik,
          ));
          _pastikanUiTimerAktif();
          break;
        case 2:
          // Background sudah masuk check-in — sinkronkan
          final DateTime waktuMulai;
          if (_currentState is CheckInDiminta) {
            final cur = _currentState as CheckInDiminta;
            waktuMulai = cur.kesempatan != bgKesempatan
                ? DateTime.now()
                : cur.waktuMulai;
          } else {
            waktuMulai = DateTime.now();
          }
          _kesempatan = bgKesempatan;
          _emitState(CheckInDiminta(
            sisaDetik: bgSisa,
            kesempatan: bgKesempatan,
            waktuMulai: waktuMulai,
          ));
          break;
      }
    });

    _amanSubscription = service.on('status_aman_dikonfirmasi').listen((_) {
      _handleAman();
    });

    _daruratSubscription = service.on('darurat_triggered').listen((_) {
      _prosesTimeoutCheckin();
    });
  }

  // ══════════════════════════════════════════════════════════════
  // TIMER AKTIF — countdown menuju check-in berikutnya
  // ══════════════════════════════════════════════════════════════

  void _pastikanUiTimerAktif() {
    if (_currentState is Aktif && _uiTickTimer == null) {
      _uiTickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        final current = _currentState;
        if (current is Aktif && current.sisaDetik > 0) {
          _emitState(Aktif(
            sisaDetik: current.sisaDetik - 1,
            intervalDetik: current.intervalDetik,
          ));
        } else if (current is Aktif && current.sisaDetik <= 0) {
          // ════ WAKTU HABIS — TRIGGER CHECK-IN ════
          _uiTickTimer?.cancel();
          _uiTickTimer = null;
          _mulaiCheckin();
        } else {
          _uiTickTimer?.cancel();
          _uiTickTimer = null;
        }
      });
    } else if (_currentState is! Aktif) {
      _uiTickTimer?.cancel();
      _uiTickTimer = null;
    }
  }

  // ══════════════════════════════════════════════════════════════
  // CHECK-IN — buka overlay + mulai countdown eskalasi
  // ══════════════════════════════════════════════════════════════

  Future<void> _mulaiCheckin() async {
    _kesempatan++;
    final durasi = _kesempatan >= 3 ? 90 : 30;
    final waktuMulai = DateTime.now();

    debugPrint(
        '[PantauService] Check-in dimulai (kesempatan=$_kesempatan, durasi=${durasi}s)');

    PantauAmanFlag.hapus();

    // 1. Emit state agar UI langsung switch ke CheckInDiminta
    _emitState(CheckInDiminta(
      sisaDetik: durasi,
      kesempatan: _kesempatan,
      waktuMulai: waktuMulai,
    ));

    // 2. Buka overlay (kesempatan 1 & 2 — di kesempatan 3 hanya in-app)
    if (_kesempatan <= 2) {
      await _bukaOverlay(waktuMulai, durasi);
    }

    // 3. Mulai countdown check-in untuk eskalasi otomatis
    _checkinTimer?.cancel();
    _checkinTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      // Jika AMAN sudah ditekan, state berubah — stop timer
      if (_currentState is! CheckInDiminta) {
        _checkinTimer?.cancel();
        _checkinTimer = null;
        return;
      }

      final berlalu = DateTime.now().difference(waktuMulai).inSeconds;
      final sisa = (durasi - berlalu).clamp(0, durasi);

      _emitState(CheckInDiminta(
        sisaDetik: sisa,
        kesempatan: _kesempatan,
        waktuMulai: waktuMulai,
      ));

      if (sisa <= 0) {
        _checkinTimer?.cancel();
        _checkinTimer = null;

        if (_kesempatan < 3) {
          // Eskalasi ke kesempatan berikutnya
          _mulaiCheckin();
        } else {
          // 3 kesempatan habis → DARURAT
          _prosesTimeoutCheckin();
        }
      }
    });
  }

  /// Buka overlay window dan kirim sinyal START dengan durasi.
  Future<void> _bukaOverlay(DateTime waktuMulai, int durasi) async {
    try {
      final active = await FlutterOverlayWindow.isActive();
      if (active) {
        await FlutterOverlayWindow.closeOverlay();
        await Future.delayed(const Duration(milliseconds: 500));
      }

      await FlutterOverlayWindow.showOverlay(
        height: 800,
        width: WindowSize.matchParent,
        alignment: OverlayAlignment.bottomCenter,
        flag: OverlayFlag.defaultFlag,
        overlayTitle: 'Konfirmasi Keamanan Aktif',
        overlayContent: 'Sigap memantau keamanan Anda.',
      );

      await Future.delayed(const Duration(milliseconds: 500));
      FlutterOverlayWindow.shareData(
          'START_OVERLAY_CHECKIN:${waktuMulai.millisecondsSinceEpoch}:$durasi');
    } catch (e) {
      debugPrint('[PantauService] Gagal tampilkan overlay: $e');
    }
  }

  // ══════════════════════════════════════════════════════════════
  // PUBLIC API
  // ══════════════════════════════════════════════════════════════

  Future<void> startWatch(int intervalMenit) async {
    _intervalDetik = intervalMenit * 60;
    _kesempatan = 0;

    final service = FlutterBackgroundService();
    bool isRunning = await service.isRunning();
    if (!isRunning) {
      await service.startService();
      await Future.delayed(const Duration(milliseconds: 1000));
    }

    service.invoke('start_timer', {
      'duration': _intervalDetik,
    });

    _emitState(Aktif(
      sisaDetik: _intervalDetik,
      intervalDetik: _intervalDetik,
    ));

    _pastikanUiTimerAktif();
  }

  Future<void> stopWatch() async {
    FlutterBackgroundService().invoke('stop_service');
    PantauAmanFlag.hapus();
    _hentikanSemuaTimer();

    try {
      final isActive = await FlutterOverlayWindow.isActive();
      if (isActive) {
        await FlutterOverlayWindow.closeOverlay();
      }
    } catch (e) {
      debugPrint('[PantauService] Gagal tutup overlay saat hentikan: $e');
    }

    _emitState(const Persiapan());
  }

  /// Dipanggil dari tombol AMAN di in-app CheckInView.
  void konfirmasiAmanLokal() {
    PantauAmanFlag.tulis();
    _handleAman();
  }

  /// Dipanggil dari tombol DARURAT manual.
  void pushDarurat() {
    _prosesTimeoutCheckin();
  }

  // ══════════════════════════════════════════════════════════════
  // INTERNAL HANDLERS
  // ══════════════════════════════════════════════════════════════

  /// Handler universal AMAN — dari overlay, in-app, atau background service.
  void _handleAman() {
    // Guard: hanya proses jika sedang check-in atau aktif
    if (_currentState is Persiapan || _currentState is DaruratTerkirim) return;

    debugPrint('[PantauService] AMAN diterima — restart loop');

    _kesempatan = 0;
    _hentikanSemuaTimer();

    FlutterBackgroundService().invoke('reset_timer');
    PantauAmanFlag.hapus();

    try {
      FlutterOverlayWindow.closeOverlay();
    } catch (e) {
      debugPrint('[PantauService] Gagal tutup overlay: $e');
    }

    // Restart loop: kembali ke Aktif dengan interval penuh
    _emitState(Aktif(
      sisaDetik: _intervalDetik,
      intervalDetik: _intervalDetik,
    ));
    _pastikanUiTimerAktif();
  }

  void _prosesTimeoutCheckin() {
    // Guard: jangan proses duplikat
    if (_currentState is DaruratTerkirim) return;

    FlutterBackgroundService().invoke('stop_service');
    PantauAmanFlag.hapus();
    _hentikanSemuaTimer();

    try {
      FlutterOverlayWindow.closeOverlay();
    } catch (e) {
      debugPrint('[PantauService] Gagal tutup overlay saat darurat: $e');
    }

    _emitState(const DaruratTerkirim());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (navigatorKey.currentState != null) {
        navigatorKey.currentState!.pushNamed('/trigger_sent');
      } else {
        debugPrint(
            '[PantauService] WARNING: NavigatorKey is null! Cannot navigate.');
      }
    });
  }

  void _hentikanSemuaTimer() {
    _uiTickTimer?.cancel();
    _uiTickTimer = null;
    _checkinTimer?.cancel();
    _checkinTimer = null;
  }

  void dispose() {
    _overlaySubscription?.cancel();
    _tickSubscription?.cancel();
    _amanSubscription?.cancel();
    _daruratSubscription?.cancel();
    _hentikanSemuaTimer();
    _stateController.close();
  }
}
