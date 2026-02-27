import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:sigap_mobile/core/constants/app_constants.dart';
import 'package:sigap_mobile/features/lapor/presentation/pages/lapor_isu_page.dart';
import 'package:sigap_mobile/features/pantau/presentation/pages/pantau_page.dart';

// Import for Clean Architecture DI
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:sigap_mobile/features/lapor/data/datasources/report_remote_data_source.dart';
import 'package:sigap_mobile/features/lapor/data/repositories/report_repository_impl.dart';
import 'package:sigap_mobile/features/lapor/domain/usecases/submit_report_usecase.dart';
import 'package:sigap_mobile/features/lapor/presentation/provider/lapor_isu_provider.dart';

/// Grid 2 layanan utama dengan efek Glassmorphism.
/// Pantau Aku: terkunci untuk Guest.
/// Buat Laporan: terbuka untuk semua pengguna.
class ServiceGrid extends StatelessWidget {
  final bool isGuest;

  const ServiceGrid({super.key, this.isGuest = false});

  void _showLoginDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(28),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppConstants.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_outline_rounded,
                size: 30,
                color: AppConstants.primaryColor,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Login Diperlukan",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppConstants.textDark,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Anda harus login terlebih dahulu\nuntuk mengakses fitur ini.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppConstants.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                ),
                child: const Text(
                  "Mengerti",
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Portal Layanan",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppConstants.textDark,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Card Pantau Aku
              Expanded(
                child: _ServiceCard(
                  icon: Icons.radar_rounded,
                  label: "Pantau Aku",
                  description: "Pantau keamananmu\nsecara berkala",
                  accentColor: const Color(0xFF0EA5E9),
                  bgColor: const Color(0xFFEFF6FF),
                  isLocked: isGuest,
                  onTap: isGuest
                      ? () => _showLoginDialog(context)
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PantauPage(),
                            ),
                          );
                        },
                ),
              ),
              const SizedBox(width: 14),
              // Card Buat Laporan
              Expanded(
                child: _ServiceCard(
                  icon: Icons.assignment_add,
                  label: "Buat Laporan",
                  description: "Laporkan kejadian\nsecara resmi",
                  accentColor: AppConstants.urgentColor,
                  bgColor: const Color(0xFFFFF5F5),
                  isLocked: false,
                  onTap: () {
                    final remoteDataSource =
                        ReportRemoteDataSourceImpl(client: http.Client());
                    final repository = ReportRepositoryImpl(
                        remoteDataSource: remoteDataSource);
                    final submitUseCase = SubmitReportUseCase(repository);

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChangeNotifierProvider(
                          create: (_) =>
                              LaporIsuProvider(submitUseCase: submitUseCase),
                          child: const LaporIsuPage(),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Card layanan besar dengan ikon, label, dan deskripsi.
class _ServiceCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final Color accentColor;
  final Color bgColor;
  final bool isLocked;
  final VoidCallback? onTap;

  const _ServiceCard({
    required this.icon,
    required this.label,
    required this.description,
    required this.accentColor,
    required this.bgColor,
    this.isLocked = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: bgColor.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: accentColor.withValues(alpha: 0.15),
              ),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ikon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: isLocked
                        ? Icon(
                            Icons.lock_rounded,
                            color: Colors.grey.shade400,
                            size: 22,
                          )
                        : Icon(
                            icon,
                            color: accentColor,
                            size: 24,
                          ),
                  ),
                ),
                const SizedBox(height: 14),
                // Label
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color:
                        isLocked ? Colors.grey.shade400 : AppConstants.textDark,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                // Deskripsi
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 11,
                    color: isLocked
                        ? Colors.grey.shade400
                        : AppConstants.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
