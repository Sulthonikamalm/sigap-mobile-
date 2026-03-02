import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sigap_mobile/core/constants/app_constants.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:vibration/vibration.dart';

/// Widget overlay independen (background service).
/// Durasi: 30 detik per kesempatan.
/// Getaran: di awal muncul + terus-menerus di ≤5 detik terakhir.
///
/// Sinyal dari main app: 'START_OVERLAY_CHECKIN:epochMs:durasiDetik'
/// durasiDetik bersifat opsional, default 30.
class OverlayCheckinWidget extends StatefulWidget {
  const OverlayCheckinWidget({super.key});

  @override
  State<OverlayCheckinWidget> createState() => _OverlayCheckinWidgetState();
}

class _OverlayCheckinWidgetState extends State<OverlayCheckinWidget> {
  // Durasi default — bisa di-override via sinyal
  int _durasiCheckin = 30;

  // Timer countdown
  int _sisaDetik = 30;
  Timer? _timer;
  bool _isStarted = false;

  // Timestamp kapan check-in dimulai (dari main app)
  DateTime? _waktuMulai;

  // Fade in
  double _opacity = 0.0;

  // Backup ticker 250ms — paksa repaint walau main timer di-throttle Android
  Timer? _backupTicker;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 50), () {
        if (mounted) setState(() => _opacity = 1.0);
      });
    });

    // Tunggu instruksi jelas dari main app.
    // Format: 'START_OVERLAY_CHECKIN:epochMs' atau 'START_OVERLAY_CHECKIN:epochMs:durasiDetik'
    FlutterOverlayWindow.overlayListener.listen((event) {
      if (event is String &&
          event.startsWith('START_OVERLAY_CHECKIN') &&
          !_isStarted) {
        _waktuMulai = DateTime.now();
        final parts = event.split(':');

        // Parse epochMs (bagian kedua)
        if (parts.length >= 2) {
          final epochMs = int.tryParse(parts[1]);
          if (epochMs != null) {
            _waktuMulai = DateTime.fromMillisecondsSinceEpoch(epochMs);
          }
        }

        // Parse durasiDetik (bagian ketiga, opsional)
        if (parts.length >= 3) {
          final durasi = int.tryParse(parts[2]);
          if (durasi != null && durasi > 0) {
            _durasiCheckin = durasi;
          }
        }

        final sisaTerhitung = _hitungSisaDetik();

        if (mounted) {
          setState(() {
            _isStarted = true;
            _sisaDetik = sisaTerhitung;
          });
        }

        // Getar awal saat overlay pertama muncul
        try {
          Vibration.vibrate(duration: 400, amplitude: 200);
        } catch (_) {}

        if (sisaTerhitung <= 0) {
          _triggerTimeout();
        } else {
          _mulaiCountdown();
        }
      }
    });
  }

  /// Hitung sisa detik berdasarkan waktu nyata — single source of truth
  int _hitungSisaDetik() {
    if (_waktuMulai == null) return _durasiCheckin;
    final berlalu = DateTime.now().difference(_waktuMulai!).inSeconds;
    return (_durasiCheckin - berlalu).clamp(0, _durasiCheckin);
  }

  void _mulaiCountdown() {
    _timer?.cancel();
    _backupTicker?.cancel();

    // Timer utama: update setiap 1 detik
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      _refreshUI();
    });

    // Backup ticker 250ms: paksa repaint jika main timer di-throttle Android
    // Tidak melakukan logika apapun, hanya trigger setState
    _backupTicker = Timer.periodic(const Duration(milliseconds: 250), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      // Hanya repaint — logika tetap di _refreshUI
      final sisa = _hitungSisaDetik();
      if (sisa != _sisaDetik && mounted) {
        setState(() => _sisaDetik = sisa);
        if (sisa <= 0) {
          t.cancel();
          _timer?.cancel();
          _triggerTimeout();
        }
      }
    });
  }

  /// Hitung dan update UI — dipanggil dari main timer
  void _refreshUI() {
    final sisa = _hitungSisaDetik();
    // setState unconditional — pastikan UI selalu sinkron walau nilainya sama
    if (mounted) {
      setState(() => _sisaDetik = sisa);
    }

    _handleGetaran(sisa);

    if (sisa <= 0) {
      _timer?.cancel();
      _backupTicker?.cancel();
      _triggerTimeout();
    }
  }

  void _handleGetaran(int detikSisa) {
    try {
      // ≤5 detik: getar terus-menerus setiap detik dengan intensitas progresif
      if (detikSisa <= 5 && detikSisa > 0) {
        final amplitudo = 200 + ((5 - detikSisa) * 11); // 200→255
        Vibration.vibrate(
          duration: 300,
          amplitude: amplitudo.clamp(200, 255),
        );
      }
      // Detik 0: Getar panjang tanda timeout
      else if (detikSisa == 0) {
        Vibration.vibrate(
          pattern: [0, 500, 200, 500],
          intensities: [0, 255, 0, 255],
        );
      }
      // Tiap 10 detik: pengingat halus
      else if (detikSisa > 5 && detikSisa % 10 == 0) {
        Vibration.vibrate(duration: 200, amplitude: 150);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _timer?.cancel();
    _backupTicker?.cancel();
    super.dispose();
  }

  void _triggerAman() {
    _timer?.cancel();
    _backupTicker?.cancel();

    // Kirim sinyal AMAN ke main app melalui IPC
    // PENTING: closeOverlay() harus ditunda agar sinyal sempat di-deliver
    // ke main app sebelum background process di-kill Android.
    try {
      FlutterOverlayWindow.shareData('AMAN');
    } catch (_) {}

    // Kirim ulang sekali lagi setelah 100ms sebagai safety net
    Future.delayed(const Duration(milliseconds: 100), () {
      try {
        FlutterOverlayWindow.shareData('AMAN');
      } catch (_) {}
    });

    // Tutup overlay setelah 500ms — memberi waktu cukup agar sinyal tersampaikan
    Future.delayed(const Duration(milliseconds: 500), () {
      try {
        FlutterOverlayWindow.closeOverlay();
      } catch (_) {}
    });
  }

  void _triggerTimeout() {
    _timer?.cancel();
    _backupTicker?.cancel();
    try {
      FlutterOverlayWindow.shareData('TIMEOUT');
    } catch (_) {}
    Future.delayed(const Duration(milliseconds: 100), () {
      try {
        FlutterOverlayWindow.shareData('TIMEOUT');
      } catch (_) {}
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      try {
        FlutterOverlayWindow.closeOverlay();
      } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    // Warna progresif: hijau > 15s, amber 6-15s, merah ≤5s
    Color progressColor;
    if (_sisaDetik <= 5) {
      progressColor = AppConstants.urgentColor;
    } else if (_sisaDetik <= 15) {
      progressColor = const Color(0xFFF59E0B);
    } else {
      progressColor = AppConstants.successColor;
    }

    return Material(
      color: Colors.transparent,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: _opacity,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 24,
                spreadRadius: 0,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 16),

                  // Baris atas: label + countdown
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Konfirmasi Keamanan',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppConstants.textSecondary,
                        ),
                      ),
                      Text(
                        '$_sisaDetik dtk',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: progressColor,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Progress bar tipis
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: _sisaDetik / _durasiCheckin,
                      minHeight: 4,
                      backgroundColor: Colors.grey.shade100,
                      valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Tombol AMAN — Fitts's Law
                  SizedBox(
                    width: double.infinity,
                    height: 64,
                    child: ElevatedButton(
                      onPressed: _triggerAman,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.successColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'AMAN \u2713',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
