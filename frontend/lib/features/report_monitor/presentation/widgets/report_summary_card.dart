import 'package:flutter/material.dart';
import 'package:sigap_mobile/core/constants/app_constants.dart';

class ReportSummaryCard extends StatelessWidget {
  final int activeReports;
  final VoidCallback? onTap;

  const ReportSummaryCard({
    super.key,
    required this.activeReports,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppConstants.primaryColor.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: AppConstants.primaryColor.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Background Ornament - KANAN BAWAH (tidak tumpang tindih)
          Positioned(
            bottom: -20,
            right: -20,
            child: Icon(
              Icons.folder_open_rounded,
              size: 90,
              color: AppConstants.primaryColor.withValues(alpha: 0.05),
            ),
          ),

          // Main Content
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Label with indicator dot
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppConstants.primaryColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'LAPORANKU',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // Count
                    Text(
                      '$activeReports Aktif',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Sedang ditindaklanjuti',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),

              // Right - Icon Container (TIDAK ada ornament di belakangnya)
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    height: 72,
                    width: 72,
                    decoration: BoxDecoration(
                      color: AppConstants.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppConstants.primaryColor.withValues(alpha: 0.15),
                      ),
                    ),
                    child: const Icon(
                      Icons.assignment_rounded,
                      size: 32,
                      color: AppConstants.primaryColor,
                    ),
                  ),
                  // Notification badge
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: AppConstants.urgentColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
