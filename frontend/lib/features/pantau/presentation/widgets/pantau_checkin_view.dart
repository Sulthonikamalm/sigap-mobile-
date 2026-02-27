import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sigap_mobile/core/constants/app_constants.dart';

/// Tampilan saat check-in diminta — user harus konfirmasi "aman".
/// Scroll-safe: menggunakan SingleChildScrollView, bukan Spacer.
/// Ini adalah tampilan PRIMARY — bukan fallback.
class PantauCheckInView extends StatelessWidget {
  final VoidCallback onKonfirmasiAman;
  final VoidCallback onDarurat;

  const PantauCheckInView({
    super.key,
    required this.onKonfirmasiAman,
    required this.onDarurat,
  });

  @override
  Widget build(BuildContext context) {
    final lebarLayar = MediaQuery.of(context).size.width;
    final paddingH =
        lebarLayar > 480 ? ((lebarLayar - 430) / 2).clamp(24.0, 120.0) : 24.0;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: paddingH),
        child: Column(
          children: [
            const SizedBox(height: 40),

            // Badge peringatan merah
            _bangunBadge(),

            const SizedBox(height: 32),

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
                onPressed: onKonfirmasiAman,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.successColor,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shadowColor: AppConstants.successColor.withValues(alpha: 0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle_outline_rounded, size: 20),
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
                onPressed: onDarurat,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: AppConstants.urgentColor.withValues(alpha: 0.5),
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
