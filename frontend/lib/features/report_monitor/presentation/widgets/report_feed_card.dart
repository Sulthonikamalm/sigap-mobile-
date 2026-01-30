import 'package:flutter/material.dart';

class ReportFeedCard extends StatelessWidget {
  final String title;
  final String location;
  final IconData categoryIcon;
  final Color categoryColor;
  final bool isPrivacyMode;
  final VoidCallback? onTap;

  const ReportFeedCard({
    super.key,
    required this.title,
    required this.location,
    required this.categoryIcon,
    required this.categoryColor,
    this.isPrivacyMode = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        // TINGGI TETAP SAMA untuk kedua mode
        height: 90,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade100,
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon Container - UKURAN SAMA
            Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                color: isPrivacyMode
                    ? Colors.grey.shade100
                    : categoryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                isPrivacyMode ? Icons.lock_rounded : categoryIcon,
                color: isPrivacyMode ? Colors.grey.shade400 : categoryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),

            // Content - STRUKTUR SAMA
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isPrivacyMode ? 'Mode Privat Aktif' : title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isPrivacyMode
                          ? Colors.grey.shade600
                          : Colors.grey.shade800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isPrivacyMode ? 'Data disamarkan untuk privasi' : location,
                    style: TextStyle(
                      fontSize: 13,
                      color: isPrivacyMode
                          ? Colors.grey.shade400
                          : Colors.grey.shade500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Arrow - SELALU ADA tapi beda warna
            Icon(
              Icons.chevron_right_rounded,
              color:
                  isPrivacyMode ? Colors.grey.shade300 : Colors.grey.shade400,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}
