import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sigap_mobile/core/constants/app_constants.dart';
import 'package:vibration/vibration.dart';

/// Tampilan saat check-in diminta — user harus konfirmasi "aman".
/// Scroll-safe: menggunakan SingleChildScrollView, bukan Spacer.
/// Ini adalah tampilan PRIMARY — bukan fallback.
///
/// Timer dihitung dari [waktuMulaiCheckin], BUKAN selalu mulai dari 90.
/// Jadi kalau user buka notif 20 detik setelah check-in dipicu,
/// timer langsung menunjukkan 70 detik (bukan 90).
class PantauCheckInView extends StatefulWidget {
  final VoidCallback onKonfirmasiAman;
  final VoidCallback onDarurat;
  final VoidCallback onTimeout;
  final int timeoutDetik;
  final DateTime waktuMulaiCheckin; // timestamp acuan hitung sisa detik

  const PantauCheckInView({
    super.key,
    required this.onKonfirmasiAman,
    required this.onDarurat,
    required this.onTimeout,
    required this.waktuMulaiCheckin,
    this.timeoutDetik = 90,
  });

  @override
  State<PantauCheckInView> createState() => _PantauCheckInViewState();
}

class _PantauCheckInViewState extends State<PantauCheckInView>
    with WidgetsBindingObserver {
  late int _sisaDetik;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Hitung sisa detik berdasarkan waktu nyata, bukan hardcode 90
    // Kalau user buka notif 20 detik setelah trigger, _sisaDetik = 70
    _hitungSisaDariTimestamp();

    // Kalau sudah habis (user buka notif setelah 90+ detik), langsung timeout
    if (_sisaDetik <= 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onTimeout();
      });
    } else {
      _mulaiTimerCheckin();
    }
  }

  /// Hitung sisa detik berdasarkan selisih waktu sekarang vs waktu mulai.
  /// Ini memastikan timer akurat walau app sempat di-background.
  void _hitungSisaDariTimestamp() {
    final detikBerlalu =
        DateTime.now().difference(widget.waktuMulaiCheckin).inSeconds;
    _sisaDetik =
        (widget.timeoutDetik - detikBerlalu).clamp(0, widget.timeoutDetik);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Saat app kembali dari background, koreksi sisa detik
    // dengan waktu nyata (bukan timer Dart yang mungkin di-throttle OS)
    if (state == AppLifecycleState.resumed) {
      _timer?.cancel();
      _hitungSisaDariTimestamp();

      if (_sisaDetik <= 0) {
        _handleVibrasiProgresif(0);
        widget.onTimeout();
      } else {
        setState(() {});
        _mulaiTimerCheckin();
      }
    }
  }

  void _mulaiTimerCheckin() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        if (_sisaDetik > 0) {
          _sisaDetik--;
          _handleVibrasiProgresif(_sisaDetik);

          if (_sisaDetik == 0) {
            t.cancel();
            _handleVibrasiProgresif(0);
            widget.onTimeout();
          }
        }
      });
    });
  }

  void _handleVibrasiProgresif(int sisaDetik) {
    try {
      // Detik 5: Peringatan Keras Menjelang Habis
      if (sisaDetik == 5) {
        Vibration.vibrate(
          pattern: [0, 500, 200, 500],
          intensities: [0, 255, 0, 255],
        );
      }
      // Detik 0: Getar Super Keras Tanda Darurat Terkirim
      else if (sisaDetik == 0) {
        Vibration.vibrate(
          pattern: [0, 1000, 500, 1000],
          intensities: [0, 255, 0, 255],
        );
      }
      // FASE 1: getar setiap 10 detik (detik 80 sampai 30)
      else if (sisaDetik > 30 && sisaDetik % 10 == 0) {
        Vibration.vibrate(duration: 250, amplitude: 150);
      }
      // Transisi ke fase 2 (pengingat ekstra keras di detik 30)
      else if (sisaDetik == 30) {
        Vibration.vibrate(
          pattern: [0, 200, 100, 200],
          intensities: [0, 200, 0, 200],
        );
      }
      // FASE 2: getar setiap 5 detik, makin keras (detik 25 sampai 10)
      else if (sisaDetik <= 25 && sisaDetik > 5 && sisaDetik % 5 == 0) {
        final durasi = 200 + ((25 - sisaDetik) * 10);
        final amplitudo = 180 + ((25 - sisaDetik) * 5);
        Vibration.vibrate(
          duration: durasi.clamp(200, 500),
          amplitude: amplitudo.clamp(180, 255),
        );
      }
      // Final SOS di 3 detik terakhir
      else if (sisaDetik == 3) {
        Vibration.vibrate(
          pattern: [0, 100, 80, 100, 80, 100],
          intensities: [0, 255, 0, 255, 0, 255],
        );
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lebarLayar = MediaQuery.of(context).size.width;
    final paddingH =
        lebarLayar > 480 ? ((lebarLayar - 430) / 2).clamp(24.0, 120.0) : 24.0;

    return Column(
      children: [
        LinearProgressIndicator(
          value: _sisaDetik / widget.timeoutDetik,
          backgroundColor: Colors.grey.shade100,
          valueColor: AlwaysStoppedAnimation<Color>(
            _sisaDetik <= 10
                ? AppConstants.urgentColor
                : AppConstants.primaryColor,
          ),
          minHeight: 4,
        ),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: paddingH),
              child: Column(
                children: [
                  const SizedBox(height: 36),

                  // Badge peringatan merah
                  _bangunBadge(),

                  const SizedBox(height: 16),

                  Text(
                    'Bantuan akan dikirim dalam $_sisaDetik detik',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: _sisaDetik <= 10
                          ? AppConstants.urgentColor
                          : AppConstants.textSecondary,
                      fontWeight:
                          _sisaDetik <= 10 ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Icon perisai merah
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppConstants.urgentColor.withValues(alpha: 0.08),
                    ),
                    child: const Icon(
                      Icons.security_rounded,
                      size: 56,
                      color: AppConstants.urgentColor,
                    ),
                  ),

                  const SizedBox(height: 24),

                  Text(
                    'Apakah Anda Aman?',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppConstants.textDark,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'Tekan tombol di bawah untuk konfirmasi bahwa '
                      'Anda dalam keadaan aman.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: AppConstants.textSecondary,
                        height: 1.6,
                      ),
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Tombol "Saya Aman"
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: widget.onKonfirmasiAman,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.successColor,
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shadowColor:
                            AppConstants.successColor.withValues(alpha: 0.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle_outline_rounded,
                              size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'SAYA AMAN',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Tombol darurat
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton(
                      onPressed: widget.onDarurat,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color:
                              AppConstants.urgentColor.withValues(alpha: 0.5),
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'KIRIM SINYAL DARURAT',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppConstants.urgentColor,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _bangunBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppConstants.urgentColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: AppConstants.urgentColor.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppConstants.urgentColor,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'KONFIRMASI DIPERLUKAN',
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppConstants.urgentColor,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
