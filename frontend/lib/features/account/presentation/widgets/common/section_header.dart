import 'package:flutter/material.dart';

/// Uppercase section header label
class SectionHeader extends StatelessWidget {
  final String title;
  final bool isSmall;

  const SectionHeader({
    super.key,
    required this.title,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: isSmall ? 10 : 11,
          fontWeight: FontWeight.bold,
          color: isSmall ? Colors.grey.shade400 : Colors.grey.shade500,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}
