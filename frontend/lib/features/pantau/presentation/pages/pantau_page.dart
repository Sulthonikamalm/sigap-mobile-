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

/// Halaman "Pantau Aku" — Orchestrator.
///
/// Mengelola state machine + timer, mendelegasikan
/// rendering ke widget-widget child yang terpisah.
///
/// State: 0=persiapan, 1=aktif, 2=check-in diminta
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

  // ── Timer & Animasi ──
  Timer? _timerInterval;
  late AnimationController _pulseController;

  // ── Overlay ──
  StreamSubscription? _overlaySubscription;

  // ── Input ──
  final TextEditingController _lokasiController = TextEditingController();
  static const int _batasKarakter = 100;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _pulseController.repeat();
  }

  @override
  void dispose() {
    _timerInterval?.cancel();
    _overlaySubscription?.cancel();
    _pulseController.dispose();
    _lokasiController.dispose();
    WidgetsBinding.instance.removeObserver(this);

    // Paksa tutup overlay saat widget di-dispose
    // Cover kasus user navigasi keluar tanpa menekan hentikan
    try {
      FlutterOverlayWindow.closeOverlay();
    } catch (_) {}

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Saat app masuk background atau detached
    // paksa matikan overlay service
    if (state == AppLifecycleState.detached ||
        state == AppLifecycleState.paused) {
      try {
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
    HapticFeedback.mediumImpact();
    setState(() {
      _state = 1;
      _sisaDetik = _intervalDipilih * 60;
    });
    _mulaiTimer();
  }

  void _mulaiTimer() {
    _timerInterval?.cancel();
    _timerInterval = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_sisaDetik > 0) {
        setState(() => _sisaDetik--);
        if (_sisaDetik == 0) {
          _mintaCheckIn();
        }
      }
    });
  }

  void _mintaCheckIn() async {
    HapticFeedback.heavyImpact();
    _timerInterval?.cancel();

    // Vibration dipanggil di sini — sebelum apapun
    // Agar getar SELALU jalan terlepas overlay berhasil atau tidak
    try {
      Vibration.vibrate(duration: 300, amplitude: 200);
    } catch (_) {}

    // PantauCheckInView SELALU ditampilkan — ini PRIMARY
    // Bukan fallback, bukan opsional
    setState(() => _state = 2);

    // Overlay dicoba sebagai TAMBAHAN opsional — best effort
    // Jika overlay gagal, PantauCheckInView sudah tampil
    try {
      final hasPermission = await FlutterOverlayWindow.isPermissionGranted();
      if (hasPermission) {
        await FlutterOverlayWindow.showOverlay(
          height: 280,
          width: WindowSize.matchParent,
          alignment: OverlayAlignment.center,
          flag: OverlayFlag.defaultFlag,
        );

        // Cancel listener sebelumnya jika ada (cegah penumpukan)
        await _overlaySubscription?.cancel();

        // Listen untuk respons dari overlay
        _overlaySubscription =
            FlutterOverlayWindow.overlayListener.listen((data) {
          if (data == 'AMAN') {
            _konfirmasiAman();
          } else if (data == 'TIMEOUT') {
            if (mounted) {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TriggerSentPage(),
                  ));
              _hentikanPantauan();
            }
          }
        });
      }
    } catch (_) {
      // Abaikan semua error overlay
      // PantauCheckInView sudah tampil sebagai primary
    }
  }

  void _konfirmasiAman() {
    HapticFeedback.mediumImpact();
    setState(() {
      _state = 1;
      _sisaDetik = _intervalDipilih * 60;
    });
    _mulaiTimer();

    _tampilkanSnackbar(
        'Konfirmasi diterima. Timer direset.', AppConstants.successColor);
  }

  void _hentikanPantauan() async {
    _timerInterval?.cancel();
    _overlaySubscription?.cancel();

    // Matikan overlay service sebelum reset state
    try {
      final isActive = await FlutterOverlayWindow.isActive();
      if (isActive) {
        await FlutterOverlayWindow.closeOverlay();
      }
    } catch (_) {}

    if (!mounted) return;

    HapticFeedback.mediumImpact();
    setState(() {
      _state = 0;
      _sisaDetik = 0;
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

  /// Hitung padding horizontal responsif.
  /// HP (<=480): 24px, Tablet: proporsional agar konten tidak melebar.
  double _hitungPaddingH(double lebarLayar) {
    if (lebarLayar <= 480) return 24;
    return ((lebarLayar - 430) / 2).clamp(24.0, 120.0);
  }

  // ── State 0: Persiapan ──
  Widget _bangunTampilanPersiapan() {
    final lebarLayar = MediaQuery.of(context).size.width;
    final paddingH = _hitungPaddingH(lebarLayar);

    return Stack(
      children: [
        // Scrollable content
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

        // Bottom bar — sticky di bawah
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
            'notifikasi check-in dalam 5 menit.',
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

  // ── Dialog keluar ──
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
