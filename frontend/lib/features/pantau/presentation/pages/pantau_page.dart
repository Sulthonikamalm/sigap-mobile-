import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sigap_mobile/core/constants/app_constants.dart';
import 'package:sigap_mobile/features/pantau/presentation/pages/pantau_kontak_page.dart';
import 'package:sigap_mobile/features/pantau/presentation/widgets/pantau_header.dart';
import 'package:sigap_mobile/features/pantau/presentation/widgets/interval_picker.dart';
import 'package:sigap_mobile/features/pantau/presentation/widgets/pantau_aktif_view.dart';
import 'package:sigap_mobile/features/pantau/presentation/widgets/pantau_checkin_view.dart';
import 'package:sigap_mobile/features/pantau/presentation/pages/trigger_sent_page.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sigap_mobile/features/pantau/services/pantau_notification_service.dart';
import 'package:sigap_mobile/features/pantau/presentation/pages/panduan_izin_page.dart';

/// Halaman "Pantau Aku" — Orchestrator.
///
/// State: 0=persiapan, 1=aktif, 2=check-in diminta
///
/// LOGIKA CHECK-IN:
///   ┌─ Timer berjalan selama T menit
///   ├─ Di titik tengah (T/2): overlay muncul
///   │   ├─ Kesempatan 1: 30 dtk (getar di awal + continuous di ≤5dtk)
///   │   ├─ Kesempatan 2: 30 dtk (hanya jika T ≥ 5 menit)
///   │   └─ Jika T < 5 menit: hanya 1 kesempatan overlay
///   ├─ Semua kesempatan habis tanpa respons:
///   │   └─ Final countdown: 90 dtk (getaran agresif, PantauCheckInView)
///   └─ Final habis tanpa respons → DARURAT dikirim
///
///   Total maks (T≥5): 30 + 30 + 90 = 150 dtk
///   Total maks (T<5): 30 + 90 = 120 dtk
class PantauPage extends StatefulWidget {
  const PantauPage({super.key});

  @override
  State<PantauPage> createState() => _PantauPageState();
}

class _PantauPageState extends State<PantauPage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  // ── State ──
  int _state = 0;
  int _intervalDipilih = 45;
  int _sisaDetik = 0;
  final List<int> _opsiInterval = [2, 5, 10, 15, 30, 45, 60];

  // ── Check-in state ──
  // 0 = belum check-in
  // 1 = kesempatan overlay 1 aktif (30 dtk)
  // 2 = kesempatan overlay 2 aktif (30 dtk)
  // 3 = final countdown aktif (90 dtk)
  int _kesempatanCheckin = 0;

  /// Jumlah maksimal kesempatan overlay sebelum final countdown.
  /// Interval ≥ 5 menit → 2 kesempatan. Interval < 5 menit → 1 kesempatan.
  int get _maksKesempatanOverlay => _intervalDipilih >= 5 ? 2 : 1;

  // Timestamp kapan fase check-in dimulai
  DateTime? _waktuMulaiCheckin;
  DateTime? _waktuMulaiPantauan; // Timestamp saat pantauan diaktifkan (state 1)

  // Pencegah race condition transisi antar fase
  bool _isProcessingPhase = false;

  // One-shot flag: AMAN selalu menang atas timeout yang berjalan paralel
  bool _amanSudahDikonfirmasi = false;

  // ── Timer & Animasi ──
  Timer? _timerInterval;
  late AnimationController _pulseController;

  // ── Overlay ──
  StreamSubscription? _overlaySubscription;
  Timer? _overlaySignalTimer;

  // ── Input ──
  final TextEditingController _lokasiController = TextEditingController();

  bool _sudahTampilPanduan = false;
  static const int _batasKarakter = 100;

  @override
  void initState() {
    super.initState();
    PantauNotificationService.init();
    WidgetsBinding.instance.addObserver(this);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _pulseController.repeat();

    // Persistent listener — hidup sepanjang umur PantauPage.
    // Tidak boleh di-cancel/recreate di _tampilkanOverlay.
    _overlaySubscription = FlutterOverlayWindow.overlayListener.listen((data) {
      if (!mounted) return;
      if (data == 'AMAN') {
        _konfirmasiAman();
      } else if (data == 'TIMEOUT') {
        _prosesKesempatanHabis();
      }
    });
  }

  @override
  void dispose() {
    _timerInterval?.cancel();
    _overlaySignalTimer?.cancel();
    _overlaySubscription?.cancel();
    _pulseController.dispose();
    _lokasiController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    PantauNotificationService.tutupSemua();

    try {
      FlutterOverlayWindow.closeOverlay();
    } catch (_) {}

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Saat app kembali ke foreground dan sedang check-in:
    // PENTING: Tunda 500ms agar platform channel events (sinyal AMAN dari overlay)
    // yang masih di-antri sempat diproses lebih dulu oleh Dart event loop.
    // Tanpa delay ini, timeout check bisa menang atas AMAN dari overlay.
    if (state == AppLifecycleState.resumed &&
        _state == 2 &&
        _waktuMulaiCheckin != null) {
      Future.delayed(const Duration(milliseconds: 3500), () {
        // Setelah delay: cek apakah AMAN sudah dikonfirmasi oleh overlay
        if (!mounted || _state != 2 || _amanSudahDikonfirmasi) return;

        final selisihDetik =
            DateTime.now().difference(_waktuMulaiCheckin!).inSeconds;
        final batasFase = _kesempatanCheckin >= 3 ? 90 : 30;
        if (selisihDetik >= batasFase) {
          _prosesKesempatanHabis();
        }
      });
    }

    if (state == AppLifecycleState.detached) {
      try {
        PantauNotificationService.tutupSemua();
        FlutterOverlayWindow.closeOverlay();
      } catch (_) {}
    }
  }

  // ═══════════════════════════════════
  // AKSI
  // ═══════════════════════════════════

  Future<void> _mintaPermisiOverlay() async {
    final hasPermission = await FlutterOverlayWindow.isPermissionGranted();
    if (!hasPermission) {
      await FlutterOverlayWindow.requestPermission();
    }
  }

  void _aktifkanPantauan() async {
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
    setState(() {
      _waktuMulaiPantauan = DateTime.now();
      _waktuMulaiCheckin = null;
      _isProcessingPhase = false;
      _state = 1;
      _sisaDetik = _intervalDipilih * 60;
      _kesempatanCheckin = 0;
    });
    PantauNotificationService.tampilkanPantauanAktif(_intervalDipilih);
    _mulaiTimer();
  }

  /// Timer utama: berjalan selama interval, trigger check-in di titik tengah.
  /// Memakai patokan waktu nyata untuk kebal terhadap OS Doze Mode.
  void _mulaiTimer() {
    _timerInterval?.cancel();
    _kesempatanCheckin = 0;
    final int totalDetik = _intervalDipilih * 60;

    _timerInterval = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final detikBerlalu =
          DateTime.now().difference(_waktuMulaiPantauan!).inSeconds;
      final targetSisa = totalDetik - detikBerlalu;

      setState(() {
        _sisaDetik = targetSisa.clamp(0, totalDetik);
      });

      // Trigger di titik tengah interval
      final triggerDetik = totalDetik ~/ 2;

      // Tambahkan buffer 5 detik: tidak trigger jika timer baru saja dimulai
      // (mencegah false trigger akibat jitter timestamp atau Doze mode)
      final detikSejakMulai =
          DateTime.now().difference(_waktuMulaiPantauan!).inSeconds;

      // <= Mencegah missed ticks due to Doze (ketika waktu tiba-tiba melompat)
      if (_sisaDetik <= triggerDetik &&
          _kesempatanCheckin == 0 &&
          !_isProcessingPhase &&
          detikSejakMulai >= 5) {
        timer.cancel();
        _timerInterval = null;
        _kesempatanCheckin = 1;
        _mintaCheckIn(kesempatan: 1);
      }
    });
  }

  /// Mulai fase check-in. Dipanggil untuk setiap kesempatan (1, 2) dan final (3).
  void _mintaCheckIn({required int kesempatan}) async {
    _timerInterval?.cancel();
    _timerInterval = null;

    HapticFeedback.heavyImpact();
    // Intensitas getar berbeda per kesempatan
    try {
      if (kesempatan <= 1) {
        Vibration.vibrate(duration: 400, amplitude: 180);
      } else if (kesempatan == 2) {
        Vibration.vibrate(duration: 600, amplitude: 220);
      } else {
        Vibration.vibrate(duration: 800, amplitude: 255);
      }
    } catch (_) {}

    // Reset flag AMAN untuk round baru
    _amanSudahDikonfirmasi = false;

    // Catat waktu mulai fase ini
    _waktuMulaiCheckin = DateTime.now();
    setState(() => _state = 2);

    // Notifikasi sesuai fase
    if (kesempatan <= 1) {
      PantauNotificationService.tampilkanCheckinDiperlukan(
        pesan: 'Konfirmasi keamanan diperlukan. Ketuk untuk merespons.',
      );
    } else if (kesempatan == 2) {
      PantauNotificationService.tampilkanCheckinDiperlukan(
        pesan: 'PERINGATAN: Tidak ada respons. '
            'Masih ada waktu 30 detik untuk konfirmasi.',
      );
    } else {
      PantauNotificationService.tampilkanCheckinDiperlukan(
        pesan: 'DARURAT: Bantuan akan dikirim otomatis dalam 90 detik. '
            'Ketuk SAYA AMAN untuk membatalkan.',
      );
    }

    // Overlay hanya untuk fase 1 & 2 (bukan final countdown)
    if (kesempatan <= 2) {
      await _tampilkanOverlay(durasiDetik: 30);
    }
  }

  /// Tampilkan overlay sebagai best-effort tambahan.
  Future<void> _tampilkanOverlay({required int durasiDetik}) async {
    try {
      final hasPermission = await FlutterOverlayWindow.isPermissionGranted();
      if (hasPermission) {
        // flutter_overlay_window membutuhkan physical pixels (bukan logical dp)
        // Hitung kepadatan layar agar tinggi window konsisten ~240dp di semua HP
        final dpr = mounted ? MediaQuery.of(context).devicePixelRatio : 2.75;
        final physicalHeight = (240 * dpr).toInt();

        await FlutterOverlayWindow.showOverlay(
          height: physicalHeight,
          width: WindowSize.matchParent,
          alignment: OverlayAlignment.bottomCenter,
          flag: OverlayFlag.defaultFlag,
          overlayTitle: 'Konfirmasi Keamanan Aktif',
          overlayContent: 'Sigap sedang memantau keamanan Anda.',
        );

        // Listener sudah persistent di initState — tidak perlu cancel/recreate di sini.

        // Kirim sinyal START secara spartan untuk memastikan Background Isolate menangkap
        final epochMs = _waktuMulaiCheckin!.millisecondsSinceEpoch;
        int attempts = 0;
        _overlaySignalTimer?.cancel();
        // 10 attempts x 800ms = 8 detik jendela pengiriman, sangat aman
        _overlaySignalTimer =
            Timer.periodic(const Duration(milliseconds: 800), (t) {
          if (attempts >= 10 || !mounted) {
            t.cancel();
          } else {
            try {
              FlutterOverlayWindow.shareData(
                  'START_OVERLAY_CHECKIN:$epochMs:$durasiDetik');
            } catch (_) {}
            attempts++;
          }
        });
      }
    } catch (_) {
      // PantauCheckInView sudah tampil sebagai primary
    }
  }

  /// Dipanggil saat timeout di PantauCheckInView atau overlay.
  /// Mengelola eskalasi secara deterministik, hanya dieksekusi 1 kali per fase.
  void _prosesKesempatanHabis() async {
    if (!mounted || _state != 2 || _isProcessingPhase) return;
    _isProcessingPhase = true;

    _overlaySignalTimer?.cancel();

    // Tutup overlay dulu jika ada — beri waktu 500ms agar benar-benar close
    try {
      final isActive = await FlutterOverlayWindow.isActive();
      if (isActive) {
        await FlutterOverlayWindow.closeOverlay();
        await Future.delayed(const Duration(milliseconds: 500));
      }
    } catch (_) {}

    if (!mounted || _state != 2) {
      _isProcessingPhase = false;
      return;
    }

    if (_kesempatanCheckin < _maksKesempatanOverlay) {
      _kesempatanCheckin++;
      _isProcessingPhase = false;
      _mintaCheckIn(kesempatan: _kesempatanCheckin);
    } else if (_kesempatanCheckin == _maksKesempatanOverlay) {
      _kesempatanCheckin = 3;
      _isProcessingPhase = false;
      _mintaCheckIn(kesempatan: 3);
    } else {
      // Final countdown habis → DARURAT
      _isProcessingPhase =
          false; // Buka kunci karena app pindah ke layar terminal
      _prosesTimeoutCheckin();
    }
  }

  void _prosesTimeoutCheckin() {
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TriggerSentPage()),
    );
    _hentikanPantauan();
  }

  void _konfirmasiAman() async {
    // AMAN harus selalu bisa diproses — tidak boleh diblokir _isProcessingPhase
    // karena timeout paralel bisa menyebabkan AMAN diabaikan
    if (!mounted || _state != 2) return;
    if (_amanSudahDikonfirmasi) return; // Idempotent: sudah diproses, skip
    _amanSudahDikonfirmasi = true;
    _isProcessingPhase = true; // Blokir fase lain yang concurrently berjalan

    HapticFeedback.mediumImpact();
    _overlaySignalTimer?.cancel();

    // Tutup overlay SEGERA sebagai aksi pertama — fire-and-forget, tidak pakai await.
    // Overlay sengaja tidak menutup dirinya sendiri (agar channel tetap hidup),
    // jadi main app yang bertanggung jawab menutupnya di sini.
    try {
      FlutterOverlayWindow.closeOverlay();
    } catch (_) {}

    // setState SEGERA setelah close — unmount PantauCheckInView secepat mungkin
    // agar observernya berhenti sebelum lifecycle resumed bisa memicunya.
    setState(() {
      _waktuMulaiPantauan = DateTime.now();
      _state = 1;
      _sisaDetik = _intervalDipilih * 60;
      _kesempatanCheckin = 0;
    });

    if (!mounted) {
      _amanSudahDikonfirmasi = false;
      _isProcessingPhase = false;
      return;
    }

    PantauNotificationService.tutupCheckin();
    PantauNotificationService.tampilkanPantauanAktif(_intervalDipilih);
    _isProcessingPhase = false;
    // _amanSudahDikonfirmasi tetap true — direset oleh _mintaCheckIn() di round berikutnya
    _mulaiTimer();

    _tampilkanSnackbar(
        'Aman. Pantauan dilanjutkan.', AppConstants.successColor);
  }

  void _hentikanPantauan() async {
    _timerInterval?.cancel();
    _overlaySignalTimer?.cancel();
    // JANGAN cancel _overlaySubscription di sini!
    // Listener harus tetap hidup sepanjang umur widget (cancel hanya di dispose).
    PantauNotificationService.tutupSemua();

    try {
      final isActive = await FlutterOverlayWindow.isActive();
      if (isActive) {
        await FlutterOverlayWindow.closeOverlay();
      }
    } catch (_) {}

    if (!mounted) return;

    HapticFeedback.mediumImpact();
    setState(() {
      _waktuMulaiPantauan = null;
      _waktuMulaiCheckin = null;
      _isProcessingPhase = false;
      _amanSudahDikonfirmasi = false;
      _state = 0;
      _sisaDetik = 0;
      _kesempatanCheckin = 0;
    });
    _tampilkanSnackbar('Pantauan dihentikan', const Color(0xFF333333));
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

  // ═══════════════════════════════════
  // BUILD
  // ═══════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _bangunAppBar(),
      body: SafeArea(
        child: switch (_state) {
          0 => _bangunTampilanPersiapan(),
          1 => PantauAktifView(
              sisaDetik: _sisaDetik,
              intervalMenit: _intervalDipilih,
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
          2 => PantauCheckInView(
              // Key unik per kesempatan agar Flutter re-create widget
              // dari awal (initState dipanggil ulang, timer di-reset)
              key: ValueKey(
                  'checkin_${_kesempatanCheckin}_${_waktuMulaiCheckin?.millisecondsSinceEpoch}'),
              onKonfirmasiAman: _konfirmasiAman,
              onDarurat: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TriggerSentPage(),
                  ),
                );
                _hentikanPantauan();
              },
              onTimeout: _prosesKesempatanHabis,
              kesempatan: _kesempatanCheckin,
              timeoutDetik: _kesempatanCheckin >= 3 ? 90 : 30,
              waktuMulaiCheckin: _waktuMulaiCheckin ?? DateTime.now(),
            ),
          _ => const SizedBox.shrink(),
        },
      ),
    );
  }

  PreferredSizeWidget _bangunAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        onPressed: () {
          if (_state != 0) {
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
        if (_state == 0)
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
                    _label('Pilih Interval Waktu'),
                    const SizedBox(height: 12),
                    IntervalPicker(
                      intervalDipilih: _intervalDipilih,
                      opsiInterval: _opsiInterval,
                      onPilih: (v) => setState(() => _intervalDipilih = v),
                    ),
                    const SizedBox(height: 28),
                    _label('Detail Lokasi / Situasi'),
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

  Widget _label(String teks) {
    return Text(
      teks,
      style: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.grey.shade700,
      ),
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
              onPressed: _aktifkanPantauan,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    AppConstants.primaryColor.withValues(alpha: 0.85),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
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
                      Navigator.pop(ctx);
                      _hentikanPantauan();
                      Navigator.pop(context);
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
