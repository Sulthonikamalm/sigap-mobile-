import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  int _state = 0; // 0=persiapan, 1=aktif, 2=check-in diminta
  int _intervalDipilih = 45;
  int _sisaDetik = 0;
  final List<int> _opsiInterval = [2, 5, 10, 15, 30, 45, 60];

  int _kesempatanCheckin = 0;
  DateTime? _waktuMulaiCheckin;

  late AnimationController _pulseController;
  final TextEditingController _lokasiController = TextEditingController();

  bool _sudahTampilPanduan = false;
  static const int _batasKarakter = 100;

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

    _cekStatusServiceAktif();
  }

  void _cekStatusServiceAktif() async {
    final service = FlutterBackgroundService();
    final isRunning = await service.isRunning();
    if (isRunning) {
      // Jika nyala, biarkan tick pertama mengatur UI
    }
  }

  void _listenToBackgroundService() {
    final service = FlutterBackgroundService();

    _tickSubscription = service.on('tick').listen((event) {
      if (event == null || !mounted) return;

      final int newState = event['state'];
      final int newSisa = event['seconds'];
      final int newKesempatan = event['kesempatan'] ?? 0;

      // Jika berpindah ke fase check-in baru (mencatat waktu mundur visual check-in)
      if (newState == 2 && _state != 2) {
        _waktuMulaiCheckin = DateTime.now();
      }

      setState(() {
        _state = newState;
        _sisaDetik = newSisa;
        _kesempatanCheckin = newKesempatan;
      });
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

  @override
  void dispose() {
    _overlaySubscription?.cancel();
    _tickSubscription?.cancel();
    _amanSubscription?.cancel();
    _daruratSubscription?.cancel();
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
      if (_state == 2 && PantauAmanFlag.adaSync()) {
        _handleAmanDariOverlay();
      }
    }
  }

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

    final service = FlutterBackgroundService();
    bool isRunning = await service.isRunning();
    if (!isRunning) {
      await service.startService();
      // JEDA KRUSIAL: Beri waktu background isolate (engine) untuk spin-up
      // sebelum kita tembak instruksi 'start_timer'
      await Future.delayed(const Duration(milliseconds: 1000));
    }

    // Kirim perintah start timer ke background service
    service.invoke('start_timer', {
      'duration': _intervalDipilih * 60,
    });

    setState(() {
      _state = 1;
      _sisaDetik = _intervalDipilih * 60;
      _kesempatanCheckin = 0;
    });
  }

  void _handleAmanDariOverlay() {
    FlutterBackgroundService().invoke('reset_timer');
    PantauAmanFlag.hapus();

    HapticFeedback.mediumImpact();
    try {
      FlutterOverlayWindow.closeOverlay();
    } catch (_) {}

    if (mounted) {
      setState(() {
        _state = 1;
        _kesempatanCheckin = 0;
        _sisaDetik = _intervalDipilih * 60;
      });
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
      _kesempatanCheckin = 0;
      _waktuMulaiCheckin = null;
    });
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
              key: ValueKey(
                  'checkin_${_kesempatanCheckin}_${_waktuMulaiCheckin?.millisecondsSinceEpoch}'),
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
                // Namun, kita sediakan ini agar interface tidak error
              },
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
