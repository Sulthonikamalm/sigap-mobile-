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
  static const int _durasiCheckin = 30;

  // Timer countdown
  int _sisaDetik = _durasiCheckin;
  Timer? _timer;

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

    // Mulai hitungan mundur
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_sisaDetik > 0) {
          _sisaDetik--;
          _handleGetaran(_sisaDetik);

          if (_sisaDetik == 0) {
            timer.cancel();
            _triggerTimeout();
          }
        }
      });
    });
  }

  void _handleGetaran(int detikSisa) {
    try {
      if (detikSisa == 15) {
        // Getar pertama, pendek dan lembut (100ms)
        Vibration.vibrate(duration: 100, amplitude: 64);
      } else if (detikSisa == 10) {
        // Getar kedua, sedikit lebih panjang (150ms)
        Vibration.vibrate(duration: 150, amplitude: 128);
      } else if (detikSisa == 5) {
        // Getar ketiga (200ms)
        Vibration.vibrate(duration: 200, amplitude: 255);
      } else if (detikSisa == 2) {
        // Getar pendek-pendek 3x (SOS ringan)
        // pattern: wait, vibrate, wait, vibrate, wait, vibrate
        Vibration.vibrate(
          pattern: [0, 100, 100, 100, 100, 100],
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
    try {
      FlutterOverlayWindow.shareData('TIMEOUT');
    } catch (_) {}
    try {
      FlutterOverlayWindow.closeOverlay();
    } catch (_) {}
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
