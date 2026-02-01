import 'package:flutter/material.dart';
import 'package:sigap_mobile/core/constants/app_constants.dart';

/// Reusable widgets untuk konsistensi UI

/// AppBar standar dengan title di tengah
PreferredSizeWidget buildStandardAppBar({
  required BuildContext context,
  required String title,
}) {
  return AppBar(
    backgroundColor: Colors.white,
    elevation: 0,
    centerTitle: true,
    leading: IconButton(
      onPressed: () => Navigator.pop(context),
      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
      color: Colors.grey.shade800,
    ),
    title: Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.grey.shade900,
        letterSpacing: 1,
      ),
    ),
    bottom: PreferredSize(
      preferredSize: const Size.fromHeight(1),
      child: Container(
        color: Colors.grey.shade100,
        height: 1,
      ),
    ),
  );
}

/// Icon container dengan background primary
Widget buildIconContainer({
  required IconData icon,
  double size = 56,
  double iconSize = 28,
}) {
  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: AppConstants.primaryColor.withOpacity(0.1),
      borderRadius: BorderRadius.circular(size * 0.286), // 16/56 ratio
    ),
    child: Icon(
      icon,
      color: AppConstants.primaryColor,
      size: iconSize,
    ),
  );
}

/// Section title dengan style konsisten
Widget buildSectionTitle(String title) {
  return Text(
    title,
    style: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: Colors.grey.shade900,
    ),
  );
}

/// Bullet point dengan icon
Widget buildBulletPoint(String text) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 6,
        height: 6,
        margin: const EdgeInsets.only(top: 6),
        decoration: const BoxDecoration(
          color: AppConstants.primaryColor,
          shape: BoxShape.circle,
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Text(
          text,
          style: TextStyle(
            fontSize: 14,
            height: 1.7,
            color: Colors.grey.shade700,
          ),
        ),
      ),
    ],
  );
}

/// Footer copyright
Widget buildFooter({String? tagline}) {
  return Column(
    children: [
      Divider(color: Colors.grey.shade200),
      const SizedBox(height: 16),
      Text(
        '© 2026 SIGAP',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade700,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        'Sistem Informasi & Garansi Perlindungan',
        style: TextStyle(
          fontSize: 11,
          color: Colors.grey.shade500,
        ),
      ),
      if (tagline != null) ...[
        const SizedBox(height: 8),
        Text(
          tagline,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: AppConstants.primaryColor,
            letterSpacing: 1,
          ),
        ),
      ],
    ],
  );
}
