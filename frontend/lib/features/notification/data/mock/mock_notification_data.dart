import 'package:flutter/material.dart';
import 'package:sigap_mobile/core/constants/app_constants.dart';
import '../models/notification_record.dart';

class MockNotificationData {
  static List<NotificationRecord> getNotifications() {
    return [
      const NotificationRecord(
        id: 'n1',
        icon: Icons.assignment_turned_in_rounded,
        iconColor: Colors.green,
        title: "Laporan Anda Diterima",
        body:
            "Laporan Isu #REP-20260222 telah berhasil dikirim dan sedang dalam antrian peninjauan oleh pihak kampus.",
        time: "10 menit yang lalu",
        section: "Hari Ini",
        isUnread: true,
      ),
      const NotificationRecord(
        id: 'n2',
        icon: Icons.shield_rounded,
        iconColor: AppConstants.primaryColor,
        title: "Selamat Datang di SIGAP",
        body:
            "Akun Anda berhasil terdaftar. Jaga keamanan Anda dan laporkan isu bila diperlukan.",
        time: "2 jam yang lalu",
        section: "Hari Ini",
        isUnread: true,
      ),
      const NotificationRecord(
        id: 'n3',
        icon: Icons.campaign_rounded,
        iconColor: Colors.orange,
        title: "Info Penting Kampus",
        body:
            "Workshop Pencegahan Kekerasan Seksual akan diadakan pada 25 Februari 2026, Gedung Utama Lt. 3.",
        time: "Kemarin, 14:30",
        section: "Kemarin",
        isUnread: false,
      ),
      const NotificationRecord(
        id: 'n4',
        icon: Icons.auto_stories_rounded,
        iconColor: Colors.deepPurple,
        title: "Artikel Baru: Kenali Tanda-Tanda",
        body:
            "Baca wawasan terbaru tentang cara mengenali tanda-tanda kekerasan seksual di lingkungan akademik.",
        time: "Kemarin, 09:15",
        section: "Kemarin",
        isUnread: false,
      ),
      const NotificationRecord(
        id: 'n5',
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
