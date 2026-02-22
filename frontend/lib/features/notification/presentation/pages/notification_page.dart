import 'package:flutter/material.dart';
import 'package:sigap_mobile/core/constants/app_constants.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Notifikasi",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppConstants.textDark,
          ),
        ),
        iconTheme: const IconThemeData(color: AppConstants.textDark),
        actions: [
          TextButton(
            onPressed: () {
              // Mark all as read
            },
            child: const Text(
              "Tandai Dibaca",
              style: TextStyle(
                fontSize: 13,
                color: AppConstants.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: _buildNotificationList(),
    );
  }

  Widget _buildNotificationList() {
    final notifications = _getMockNotifications();

    if (notifications.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final notif = notifications[index];
        final isFirst = index == 0;

        // Section header (Hari Ini / Kemarin / Lebih Lama)
        Widget? sectionHeader;
        if (isFirst || notif.section != notifications[index - 1].section) {
          sectionHeader = Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: Text(
              notif.section,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade500,
                letterSpacing: 0.5,
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (sectionHeader != null) sectionHeader,
            _NotificationTile(notification: notif),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppConstants.primaryColor.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_off_rounded,
              size: 48,
              color: AppConstants.primaryColor.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "Belum Ada Notifikasi",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppConstants.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Notifikasi terbaru akan muncul di sini.",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  List<_NotificationData> _getMockNotifications() {
    return [
      _NotificationData(
        icon: Icons.assignment_turned_in_rounded,
        iconColor: Colors.green,
        title: "Laporan Anda Diterima",
        body:
            "Laporan Isu #REP-20260222 telah berhasil dikirim dan sedang dalam antrian peninjauan oleh pihak kampus.",
        time: "10 menit yang lalu",
        section: "Hari Ini",
        isUnread: true,
      ),
      _NotificationData(
        icon: Icons.shield_rounded,
        iconColor: AppConstants.primaryColor,
        title: "Selamat Datang di SIGAP",
        body:
            "Akun Anda berhasil terdaftar. Jaga keamanan Anda dan laporkan isu bila diperlukan.",
        time: "2 jam yang lalu",
        section: "Hari Ini",
        isUnread: true,
      ),
      _NotificationData(
        icon: Icons.campaign_rounded,
        iconColor: Colors.orange,
        title: "Info Penting Kampus",
        body:
            "Workshop Pencegahan Kekerasan Seksual akan diadakan pada 25 Februari 2026, Gedung Utama Lt. 3.",
        time: "Kemarin, 14:30",
        section: "Kemarin",
        isUnread: false,
      ),
      _NotificationData(
        icon: Icons.auto_stories_rounded,
        iconColor: Colors.deepPurple,
        title: "Artikel Baru: Kenali Tanda-Tanda",
        body:
            "Baca wawasan terbaru tentang cara mengenali tanda-tanda kekerasan seksual di lingkungan akademik.",
        time: "Kemarin, 09:15",
        section: "Kemarin",
        isUnread: false,
      ),
      _NotificationData(
        icon: Icons.update_rounded,
        iconColor: Colors.teal,
        title: "Pembaruan Aplikasi v0.2.0",
        body:
            "Fitur baru: Formulir Lapor Isu yang lebih mudah dengan 6 langkah sederhana.",
        time: "20 Feb 2026",
        section: "Lebih Lama",
        isUnread: false,
      ),
    ];
  }
}

class _NotificationTile extends StatelessWidget {
  final _NotificationData notification;

  const _NotificationTile({required this.notification});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: notification.isUnread
            ? AppConstants.primaryColor.withValues(alpha: 0.04)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: notification.isUnread
              ? AppConstants.primaryColor.withValues(alpha: 0.15)
              : Colors.grey.shade200,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon Container
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: notification.iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                notification.icon,
                color: notification.iconColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: notification.isUnread
                                ? FontWeight.bold
                                : FontWeight.w600,
                            color: AppConstants.textDark,
                          ),
                        ),
                      ),
                      if (notification.isUnread)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppConstants.primaryColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    notification.time,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade400,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationData {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String body;
  final String time;
  final String section;
  final bool isUnread;

  _NotificationData({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.body,
    required this.time,
    required this.section,
    this.isUnread = false,
  });
}
