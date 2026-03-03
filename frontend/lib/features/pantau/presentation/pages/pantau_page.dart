import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sigap_mobile/core/constants/app_constants.dart';
import 'package:sigap_mobile/features/pantau/domain/status_pantauan.dart';
import 'package:sigap_mobile/features/pantau/presentation/pages/pantau_kontak_page.dart';
import 'package:sigap_mobile/features/pantau/presentation/widgets/pantau_header.dart';
import 'package:sigap_mobile/features/pantau/presentation/widgets/interval_picker.dart';
import 'package:sigap_mobile/features/pantau/presentation/widgets/pantau_aktif_view.dart';
import 'package:sigap_mobile/features/pantau/presentation/widgets/pantau_checkin_view.dart';
import 'package:sigap_mobile/features/pantau/presentation/pages/trigger_sent_page.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sigap_mobile/features/pantau/services/pantau_aman_flag.dart';
import 'package:sigap_mobile/features/pantau/presentation/pages/panduan_izin_page.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

class PantauPage extends StatefulWidget {
  const PantauPage({super.key});

  @override
  State<PantauPage> createState() => _PantauPageState();
}

class _PantauPageState extends State<PantauPage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  // ── State ──
  StatusPantauan _status = const Persiapan();
  int _intervalDipilih = 45;
  final List<int> _opsiInterval = [2, 5, 10, 15, 30, 45, 60];

  late AnimationController _pulseController;
  final TextEditingController _lokasiController = TextEditingController();

  bool _sudahTampilPanduan = false;
  bool _sedangMengaktifkan = false; // FIX: Loading state cegah double-tap
  static const int _batasKarakter = 100;

  // Timer lokal agar UI tetap berjalan mulus meskipun service tick tersendat.
  // Service tick tetap override/koreksi nilai saat diterima.
  Timer? _uiTickTimer;

  StreamSubscription? _overlaySubscription;
  StreamSubscription? _tickSubscription;
  StreamSubscription? _amanSubscription;
  StreamSubscription? _daruratSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _pulseController.repeat();

    _listenToBackgroundService();

    // Listener overlay (Jaga-jaga jika tombol ditapped dari overlay & dikirim via IPC)
    _overlaySubscription = FlutterOverlayWindow.overlayListener.listen((data) {
      if (!mounted) return;
      if (data == 'AMAN' || data == 'AMAN_CONFIRMED') {
        _handleAmanDariOverlay();
      }
    });
  }

  void _listenToBackgroundService() {
    final service = FlutterBackgroundService();

    _tickSubscription = service.on('tick').listen((event) {
      if (event == null || !mounted) return;

      final int newState = event['state'];
      final int newSisa = event['seconds'];
      final int newKesempatan = event['kesempatan'] ?? 0;

      setState(() {
        switch (newState) {
          case 1:
            _status = Aktif(
              sisaDetik: newSisa,
              intervalDetik: _intervalDipilih * 60,
            );
          case 2:
            // Catat waktu mulai check-in jika baru masuk fase ini
            final DateTime waktuMulai;
            if (_status is CheckInDiminta) {
              final current = _status as CheckInDiminta;
              // Jika kesempatan berubah, ini adalah fase check-in baru
              waktuMulai = current.kesempatan != newKesempatan
                  ? DateTime.now()
                  : current.waktuMulai;
            } else {
              waktuMulai = DateTime.now();
            }
            _status = CheckInDiminta(
              sisaDetik: newSisa,
              kesempatan: newKesempatan,
              waktuMulai: waktuMulai,
            );
          default:
            break;
        }
      });

      // Pastikan UI tick timer berjalan saat status Aktif
      _pastikanUiTickTimerBerjalan();

      // FIX: Stop pulse saat bukan persiapan — hemat CPU
      _sinkronkanPulseController();
    });

    _amanSubscription = service.on('status_aman_dikonfirmasi').listen((event) {
      if (!mounted) return;
      _handleAmanDariOverlay();
    });

    _daruratSubscription = service.on('darurat_triggered').listen((event) {
      if (!mounted) return;
      _prosesTimeoutCheckin();
    });
  }

  /// Timer lokal 1 detik untuk UI countdown.
  ///
  /// PantauAktifView adalah StatelessWidget — ia tidak punya timer sendiri.
  /// Tanpa timer ini, jika service tick terlambat atau hilang (IPC latency,
  /// device throttle, slow spin-up), countdown di UI akan freeze.
  ///
  /// Saat service tick diterima, nilainya OVERRIDE _status.sisaDetik,
  /// sehingga timer lokal dan service selalu tersinkronisasi.
  ///
  /// KRUSIAL: Saat countdown mencapai 0, timer ini memicu transisi ke
  /// CheckInDiminta. Ini adalah FALLBACK jika service tidak berjalan
  /// atau `start_timer` invoke hilang saat spin-up.
  void _pastikanUiTickTimerBerjalan() {
    if (_status is Aktif && _uiTickTimer == null) {
      _uiTickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) {
          _uiTickTimer?.cancel();
          _uiTickTimer = null;
          return;
        }

        final current = _status;
        if (current is Aktif && current.sisaDetik > 0) {
          setState(() {
            _status = Aktif(
              sisaDetik: current.sisaDetik - 1,
              intervalDetik: current.intervalDetik,
            );
          });
        } else if (current is Aktif && current.sisaDetik <= 0) {
          // ══════════════════════════════════════════════════
          // WAKTU HABIS — Transisi ke fase Check-in
          // ══════════════════════════════════════════════════
          _uiTickTimer?.cancel();
          _uiTickTimer = null;

          debugPrint(
              '[PantauPage] UI timer habis — transisi ke CheckInDiminta');

          // Retry start_timer ke service (jika invoke awal hilang)
          FlutterBackgroundService().invoke('start_timer', {
            'duration': _intervalDipilih * 60,
          });

          final waktuMulai = DateTime.now();
          setState(() {
            _status = CheckInDiminta(
              sisaDetik: 30, // Kesempatan pertama = 30 detik
              kesempatan: 1,
              waktuMulai: waktuMulai,
            );
          });
          _sinkronkanPulseController();
        } else {
          // Bukan Aktif lagi — stop timer lokal
          _uiTickTimer?.cancel();
          _uiTickTimer = null;
        }
      });
    } else if (_status is! Aktif) {
      _uiTickTimer?.cancel();
      _uiTickTimer = null;
    }
  }

  void _hentikanUiTickTimer() {
    _uiTickTimer?.cancel();
    _uiTickTimer = null;
  }

  /// Sinkronkan AnimationController untuk pulse berdasarkan status.
  /// Hanya aktif saat Persiapan — hemat CPU saat monitoring berjalan.
  void _sinkronkanPulseController() {
    if (_status is Persiapan) {
      if (!_pulseController.isAnimating) {
        _pulseController.repeat();
      }
    } else {
      if (_pulseController.isAnimating) {
        _pulseController.stop();
      }
    }
  }

  @override
  void dispose() {
    _overlaySubscription?.cancel();
    _tickSubscription?.cancel();
    _amanSubscription?.cancel();
    _daruratSubscription?.cancel();
    _hentikanUiTickTimer();
    _pulseController.dispose();
    _lokasiController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Flag diperiksa di UI juga agar seketika ter-update (tidak tunggu tick 1 detik)
      if (_status is CheckInDiminta && PantauAmanFlag.adaSync()) {
        _handleAmanDariOverlay();
      }
    }
  }

  Future<void> _mintaPermisiOverlay() async {
    try {
      final hasPermission = await FlutterOverlayWindow.isPermissionGranted();
      if (!hasPermission) {
        await FlutterOverlayWindow.requestPermission();
      }
    } catch (e) {
      debugPrint('[PantauPage] Gagal minta izin overlay: $e');
    }
  }

  void _aktifkanPantauan() async {
    // FIX: Cegah double-tap dan beri visual feedback
    if (_sedangMengaktifkan) return;
    setState(() => _sedangMengaktifkan = true);

    try {
      await _mintaPermisiOverlay();
      await [
        Permission.notification,
        Permission.systemAlertWindow,
        Permission.ignoreBatteryOptimizations,
      ].request();

      if (!_sudahTampilPanduan && mounted) {
        _sudahTampilPanduan = true;
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PanduanIzinPage()),
        );
      }

      if (!mounted) return;

      HapticFeedback.mediumImpact();

      final service = FlutterBackgroundService();
      bool isRunning = await service.isRunning();
      if (!isRunning) {
        await service.startService();
        // JEDA KRUSIAL: Beri waktu background isolate untuk spin-up
        await Future.delayed(const Duration(milliseconds: 1000));
      }

      // Kirim perintah start timer ke background service
      service.invoke('start_timer', {
        'duration': _intervalDipilih * 60,
      });

      if (!mounted) return;

      setState(() {
        _status = Aktif(
          sisaDetik: _intervalDipilih * 60,
          intervalDetik: _intervalDipilih * 60,
        );
      });

      _pastikanUiTickTimerBerjalan();
      _sinkronkanPulseController();
    } catch (e) {
      debugPrint('[PantauPage] Gagal mengaktifkan pantauan: $e');
      if (mounted) {
        _tampilkanSnackbar(
            'Gagal mengaktifkan pantauan', AppConstants.urgentColor);
      }
    } finally {
      if (mounted) {
        setState(() => _sedangMengaktifkan = false);
      }
    }
  }

  void _handleAmanDariOverlay() {
    FlutterBackgroundService().invoke('reset_timer');
    PantauAmanFlag.hapus();

    HapticFeedback.mediumImpact();
    try {
      FlutterOverlayWindow.closeOverlay();
    } catch (e) {
      debugPrint('[PantauPage] Gagal tutup overlay: $e');
    }

    if (mounted) {
      _hentikanUiTickTimer(); // Reset timer lokal sebelum set state baru
      setState(() {
        _status = Aktif(
          sisaDetik: _intervalDipilih * 60,
          intervalDetik: _intervalDipilih * 60,
        );
      });
      _pastikanUiTickTimerBerjalan();
      _sinkronkanPulseController();
      _tampilkanSnackbar(
          'Aman. Pantauan dilanjutkan.', AppConstants.successColor);
    }
  }

  // Dipanggil UI (PantauCheckInView)
  void _konfirmasiAmanLokal() {
    PantauAmanFlag.tulis(); // Pastikan flag ditulis agar service juga baca
    _handleAmanDariOverlay();
  }

  void _hentikanPantauan() async {
    FlutterBackgroundService().invoke('stop_service');
    PantauAmanFlag.hapus();
    _hentikanUiTickTimer();

    try {
      final isActive = await FlutterOverlayWindow.isActive();
      if (isActive) {
        await FlutterOverlayWindow.closeOverlay();
      }
    } catch (e) {
      debugPrint('[PantauPage] Gagal tutup overlay saat hentikan: $e');
    }

    if (!mounted) return;

    HapticFeedback.mediumImpact();
    setState(() {
      _status = const Persiapan();
    });
    _sinkronkanPulseController();
    _tampilkanSnackbar('Pantauan dihentikan', const Color(0xFF333333));
  }

  void _prosesTimeoutCheckin() {
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TriggerSentPage()),
    );
    _hentikanPantauan();
  }

  void _tampilkanSnackbar(String pesan, Color warna) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(pesan,
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: warna,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _bangunAppBar(),
      body: SafeArea(
        child: switch (_status) {
          Persiapan() => _bangunTampilanPersiapan(),
          Aktif(sisaDetik: final sisa, intervalDetik: final interval) =>
            PantauAktifView(
              sisaDetik: sisa,
              intervalMenit: interval ~/ 60,
              lokasiUser: _lokasiController.text,
              onHentikan: _hentikanPantauan,
              onDarurat: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TriggerSentPage(),
                  ),
                );
                _hentikanPantauan();
              },
            ),
          CheckInDiminta(
            kesempatan: final kesempatan,
            waktuMulai: final waktuMulai
          ) =>
            PantauCheckInView(
              key: ValueKey(
                  'checkin_${kesempatan}_${waktuMulai.millisecondsSinceEpoch}'),
              onKonfirmasiAman: _konfirmasiAmanLokal,
              onDarurat: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TriggerSentPage(),
                  ),
                );
                _hentikanPantauan();
              },
              onTimeout: () {
                // UI tidak paksa timeout eskalasi, biarkan service yang pindah state
              },
              kesempatan: kesempatan,
              timeoutDetik: kesempatan >= 3 ? 90 : 30,
              waktuMulaiCheckin: waktuMulai,
            ),
          DaruratTerkirim() => const SizedBox.shrink(),
        },
      ),
    );
  }

  PreferredSizeWidget _bangunAppBar() {
    final adalahPersiapan = _status is Persiapan;

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        onPressed: () {
          if (!adalahPersiapan) {
            _tampilkanDialogKeluar();
          } else {
            Navigator.pop(context);
          }
        },
        icon: Icon(Icons.arrow_back_ios_new_rounded,
            size: 20, color: Colors.grey.shade800),
      ),
      centerTitle: true,
      title: Text(
        'Pantau Aku',
        style: GoogleFonts.poppins(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: Colors.grey.shade900,
          letterSpacing: -0.3,
        ),
      ),
      actions: [
        if (adalahPersiapan)
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PantauKontakPage()),
            ),
            icon: Icon(Icons.settings_outlined,
                size: 22, color: Colors.grey.shade800),
          ),
      ],
    );
  }

  double _hitungPaddingH(double lebarLayar) {
    if (lebarLayar <= 480) return 24;
    return ((lebarLayar - 430) / 2).clamp(24.0, 120.0);
  }

  Widget _bangunTampilanPersiapan() {
    final lebarLayar = MediaQuery.of(context).size.width;
    final paddingH = _hitungPaddingH(lebarLayar);

    return Stack(
      children: [
        SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PantauHeader(
                pulseController: _pulseController,
              ),
              const SizedBox(height: 32),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: paddingH),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pilih Interval Waktu',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    IntervalPicker(
                      intervalDipilih: _intervalDipilih,
                      opsiInterval: _opsiInterval,
                      onPilih: (v) => setState(() => _intervalDipilih = v),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'Detail Lokasi / Situasi',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _bangunTextareaLokasi(),
                  ],
                ),
              ),
            ],
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _bangunBottomBar(paddingH),
        ),
      ],
    );
  }

  Widget _bangunTextareaLokasi() {
    return TextField(
      controller: _lokasiController,
      maxLines: 5,
      maxLength: _batasKarakter,
      onChanged: (_) => setState(() {}),
      style: GoogleFonts.poppins(fontSize: 14, color: AppConstants.textDark),
      decoration: InputDecoration(
        hintText:
            'Tuliskan detail lokasi Anda saat ini atau tujuan perjalanan...',
        hintStyle:
            GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade400),
        filled: true,
        fillColor: Colors.transparent,
        contentPadding: const EdgeInsets.all(16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppConstants.primaryColor, width: 1.5),
        ),
      ),
    );
  }

  Widget _bangunBottomBar(double paddingH) {
    return Container(
      padding: EdgeInsets.fromLTRB(paddingH, 24, paddingH, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Kontak darurat akan menerima notifikasi otomatis beserta '
            'lokasi terakhir Anda jika Anda tidak merespons '
            'notifikasi check-in.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
                fontSize: 11,
                color: Colors.grey.shade500,
                height: 1.6,
                fontWeight: FontWeight.w400),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              // FIX: Disable saat sedang mengaktifkan (cegah double-tap)
              onPressed: _sedangMengaktifkan ? null : _aktifkanPantauan,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    AppConstants.primaryColor.withValues(alpha: 0.85),
                disabledBackgroundColor:
                    AppConstants.primaryColor.withValues(alpha: 0.4),
                foregroundColor: Colors.white,
                disabledForegroundColor: Colors.white70,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _sedangMengaktifkan
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'MENGAKTIFKAN...',
                          style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2),
                        ),
                      ],
                    )
                  : Text(
                      'AKTIFKAN PANTAUAN',
                      style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _tampilkanDialogKeluar() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(28),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppConstants.urgentColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.warning_rounded,
                  size: 28, color: AppConstants.urgentColor),
            ),
            const SizedBox(height: 16),
            Text('Hentikan Pantauan?',
                style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.textDark)),
            const SizedBox(height: 8),
            Text(
              'Kontak darurat tidak akan\nmenerima notifikasi keamanan.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                  fontSize: 13, color: AppConstants.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text('Batal',
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            color: AppConstants.textSecondary)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // FIX: Urutan yang benar agar tidak setState setelah unmount.
                      // 1. Tutup dialog
                      Navigator.pop(ctx);
                      // 2. Keluar halaman PantauPage
                      Navigator.pop(context);
                      // 3. Cleanup di background (service + overlay)
                      //    Ini aman karena invoke ke service tidak butuh mounted widget.
                      FlutterBackgroundService().invoke('stop_service');
                      PantauAmanFlag.hapus();
                      try {
                        FlutterOverlayWindow.closeOverlay();
                      } catch (e) {
                        debugPrint(
                            '[PantauPage] Gagal tutup overlay saat keluar: $e');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.urgentColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text('Hentikan',
                        style:
                            GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
