import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sigap_mobile/core/constants/app_constants.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:vibration/vibration.dart';

/// Widget yang berjalan independen di dalam overlay background.
/// TIDAK ADA Navigasi, Scaffold, atau hal kompleks lain.
class OverlayCheckinWidget extends StatefulWidget {
  const OverlayCheckinWidget({super.key});

  @override
  State<OverlayCheckinWidget> createState() => _OverlayCheckinWidgetState();
}

class _OverlayCheckinWidgetState extends State<OverlayCheckinWidget> {
  // Durasi konfirmasi check-in (detik)
  static const int _durasiCheckin = 90;

  // Timer countdown
  int _sisaDetik = _durasiCheckin;
  Timer? _timer;
  bool _isStarted = false;

  // Timestamp kapan check-in dimulai (dari main app)
  DateTime? _waktuMulai;

  // Trauma-informed fade in
  double _opacity = 0.0;

  @override
  void initState() {
    super.initState();

    // Memicu fade-in perlahan agar tidak mengagetkan (Startle response)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 50), () {
        if (mounted) setState(() => _opacity = 1.0);
      });
    });

    // Tunggu instruksi jelas dari main app sebelum mulai countdown dan getar.
    // Ini mencegah getar acak jika Android tiba-tiba nge-restart Foreground Service ini.
    // Format sinyal: 'START_OVERLAY_CHECKIN:epochMilliseconds'
    FlutterOverlayWindow.overlayListener.listen((event) {
      if (event is String &&
          event.startsWith('START_OVERLAY_CHECKIN') &&
          !_isStarted) {
        // Parse timestamp dari sinyal
        // Kalau ada ':epochMs' di belakang, pakai itu untuk hitung sisa detik
        _waktuMulai = DateTime.now(); // default: sekarang
        final parts = event.split(':');
        if (parts.length >= 2) {
          final epochMs = int.tryParse(parts.last);
          if (epochMs != null) {
            _waktuMulai = DateTime.fromMillisecondsSinceEpoch(epochMs);
          }
        }

        // Hitung sisa detik berdasarkan waktu nyata
        final detikBerlalu = DateTime.now().difference(_waktuMulai!).inSeconds;
        final sisaTerhitung =
            (_durasiCheckin - detikBerlalu).clamp(0, _durasiCheckin);

        if (mounted) {
          setState(() {
            _isStarted = true;
            _sisaDetik = sisaTerhitung;
          });
        }

        if (sisaTerhitung <= 0) {
          _triggerTimeout();
        } else {
          _mulaiCountdown();
        }
      }
    });
  }

  void _mulaiCountdown() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_sisaDetik > 0) {
          _sisaDetik--;
          _handleGetaran(_sisaDetik);

          if (_sisaDetik == 0) {
            timer.cancel();
            _handleGetaran(0);
            _triggerTimeout();
          }
        }
      });
    });
  }

  void _handleGetaran(int detikSisa) {
    try {
      // Detik 5: Peringatan Keras Menjelang Habis
      if (detikSisa == 5) {
        Vibration.vibrate(
          pattern: [0, 500, 200, 500],
          intensities: [0, 255, 0, 255],
        );
      }
      // Detik 0: Getar Super Keras Tanda Darurat Terkirim
      else if (detikSisa == 0) {
        Vibration.vibrate(
          pattern: [0, 1000, 500, 1000],
          intensities: [0, 255, 0, 255],
        );
      }
      // FASE 1: getar setiap 10 detik (detik 80 sampai 30)
      else if (detikSisa > 30 && detikSisa % 10 == 0) {
        Vibration.vibrate(duration: 250, amplitude: 150);
      }
      // Transisi ke fase 2 (pengingat ekstra keras di detik 30)
      else if (detikSisa == 30) {
        Vibration.vibrate(
          pattern: [0, 200, 100, 200],
          intensities: [0, 200, 0, 200],
        );
      }
      // FASE 2: getar setiap 5 detik, makin keras (detik 25 sampai 10)
      else if (detikSisa <= 25 && detikSisa > 5 && detikSisa % 5 == 0) {
        final durasi = 200 + ((25 - detikSisa) * 10);
        final amplitudo = 180 + ((25 - detikSisa) * 5);
        Vibration.vibrate(
          duration: durasi.clamp(200, 500),
          amplitude: amplitudo.clamp(180, 255),
        );
      }
      // Final SOS di 3 detik terakhir
      else if (detikSisa == 3) {
        Vibration.vibrate(
          pattern: [0, 100, 80, 100, 80, 100],
          intensities: [0, 255, 0, 255, 0, 255],
        );
      }
    } catch (_) {
      // Abaikan error (fail silently jika plugin haptic terblokir dari background service)
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _triggerAman() {
    _timer?.cancel();

    // Fire and forget, hapus await dan amankan dengan try catch
    // Karena dipanggil dari background service tanpa UI context penuh
    try {
      FlutterOverlayWindow.shareData('AMAN');
    } catch (_) {}
    try {
      FlutterOverlayWindow.closeOverlay();
    } catch (_) {}
  }

  void _triggerTimeout() {
    _timer?.cancel(); // Cancel timer DULU sebelum apapun

    try {
      FlutterOverlayWindow.shareData('TIMEOUT');
    } catch (_) {}

    // Delay 300ms pastikan shareData terkirim ke pantau_page
    // sebelum overlay ditutup
    Future.delayed(const Duration(milliseconds: 300), () {
      try {
        FlutterOverlayWindow.closeOverlay();
      } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    // Progressive Urgency Colors
    final isAmberZone = _sisaDetik > 10 && _sisaDetik <= 20;
    final isRedZone = _sisaDetik <= 10;

    Color progressColor = AppConstants.successColor;
    if (isAmberZone) progressColor = const Color(0xFFF59E0B);
    if (isRedZone) progressColor = AppConstants.urgentColor;

    // Progressive Urgency Text
    String countdownText = '$_sisaDetik detik';
    Color countdownColor = AppConstants.textSecondary;
    FontWeight countdownWeight = FontWeight.w500;

    if (isAmberZone) {
      countdownText = '$_sisaDetik detik tersisa';
      countdownColor = const Color(0xFFF59E0B);
    } else if (isRedZone) {
      countdownText = '$_sisaDetik detik!';
      countdownColor = AppConstants.urgentColor;
      countdownWeight = FontWeight.w600;
    }

    return Material(
      color: Colors.transparent,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: _opacity,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            children: [
              const Spacer(flex: 3),

              // Elemen 1: Label Tenang
              Text(
                'Konfirmasi Keamanan',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppConstants.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),

              const Spacer(flex: 2),

              // Elemen 2: Fitts's Law Tombol Besar
              FractionallySizedBox(
                widthFactor: 0.85,
                child: Container(
                  height: 64,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppConstants.successColor.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
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
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ),

              const Spacer(flex: 4),

              // Elemen 3: Progress & Countdown (Time Pressure Design)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    LayoutBuilder(builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      // Progress mengecil ke arah kiri
                      final barWidth = width * (_sisaDetik / _durasiCheckin);

                      return Container(
                        width: width,
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: AnimatedContainer(
                            duration: const Duration(seconds: 1),
                            width: barWidth,
                            height: 6,
                            decoration: BoxDecoration(
                              color: progressColor,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 8),
                    Text(
                      countdownText,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: countdownWeight,
                        color: countdownColor,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
