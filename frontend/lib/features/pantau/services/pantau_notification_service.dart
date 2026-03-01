import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class PantauNotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const int _idAktif = 1001;
  static const int _idCheckin = 1002;

  static Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(
      const InitializationSettings(android: android),
    );
  }

  // Tampilkan notifikasi persistent "Pantauan Aktif"
  // Ini yang membuat service tetap hidup di MIUI
  static Future<void> tampilkanPantauanAktif(int intervalMenit) async {
    const androidDetails = AndroidNotificationDetails(
      'pantau_aktif',
      'Pantauan Aktif',
      channelDescription: 'Status pemantauan keamanan aktif',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true, // Tidak bisa di-swipe, harus dari app
      autoCancel: false,
      showWhen: false,
      icon: '@mipmap/ic_launcher',
    );
    await _plugin.show(
      _idAktif,
      'Pantau Aku Aktif',
      'Konfirmasi setiap $intervalMenit menit. Ketuk untuk membuka.',
      const NotificationDetails(android: androidDetails),
    );
  }

  // Tampilkan notifikasi urgent "Konfirmasi Diperlukan"
  // Muncul saat check-in dipicu, sebagai layer tambahan
  // Parameter [pesan] bisa di-custom per kesempatan (1, 2, atau final)
  static Future<void> tampilkanCheckinDiperlukan({
    String pesan = 'Tekan untuk konfirmasi. '
        'Bantuan dikirim otomatis dalam 90 detik.',
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'pantau_checkin',
      'Konfirmasi Keamanan',
      channelDescription: 'Permintaan konfirmasi keamanan',
      importance: Importance.max, // Heads-up notification
      priority: Priority.max,
      ongoing: false,
      autoCancel: true,
      fullScreenIntent: true, // Muncul di lock screen juga
      category: AndroidNotificationCategory.alarm,
      icon: '@mipmap/ic_launcher',
    );
    await _plugin.show(
      _idCheckin,
      'Apakah Anda Aman?',
      pesan,
      const NotificationDetails(android: androidDetails),
    );
  }

  // Tutup semua notifikasi Pantau Aku
  static Future<void> tutupSemua() async {
    await _plugin.cancel(_idAktif);
    await _plugin.cancel(_idCheckin);
  }

  // Tutup hanya notifikasi check-in
  static Future<void> tutupCheckin() async {
    await _plugin.cancel(_idCheckin);
  }
}
