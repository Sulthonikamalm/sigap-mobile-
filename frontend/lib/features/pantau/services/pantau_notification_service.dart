import 'dart:async';
import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:sigap_mobile/features/pantau/services/pantau_aman_flag.dart';

class PantauNotificationService {
  static const String notificationChannelId = 'pantau_aman_channel';
  static const int notificationId = 888;

  static Future<void> initializeService() async {
    final service = FlutterBackgroundService();

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      notificationChannelId,
      'Pantau Aman Service',
      description: 'Menjalankan layanan pemantauan keamanan di background',
      importance: Importance.high,
    );

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart, // Fungsi utama background
        autoStart: false, // Jangan auto start, biar dikontrol UI
        isForegroundMode: true,
        notificationChannelId: notificationChannelId,
        initialNotificationTitle: 'Pantau Aman Aktif',
        initialNotificationContent: 'Menyiapkan pemantauan...',
        foregroundServiceNotificationId: notificationId,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
  }

  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    return true;
  }

  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();

    Timer? timer;
    int sisaWaktu = 0;
    int durasiAsli = 0;
    int stateInfo = 1; // 1: Pantauan Aktif, 2: Check-in, 3: Darurat
    int kesempatan = 0;

    void updateNotification() {
      if (service is AndroidServiceInstance) {
        String title = "Sigap Pantau Aku";
        String content = "";
        if (stateInfo == 1) {
          content = "Pantauan Aktif. Cek dalam $sisaWaktu dtk";
        } else if (stateInfo == 2) {
          title = "⚠️ KONFIRMASI KEAMANAN!";
          content = "Ketuk SAYA AMAN. (Sisa $sisaWaktu dtk)";
        } else if (stateInfo == 3) {
          title = "🚨 DARURAT!";
          content = "Tanda bahaya telah dikirim otomatis!";
        }

        service.setForegroundNotificationInfo(title: title, content: content);
      }
    }

    void mintaCheckIn() async {
      PantauAmanFlag.hapus();

      service.invoke(
          'tick', {'seconds': sisaWaktu, 'state': 2, 'kesempatan': kesempatan});
      updateNotification();

      if (kesempatan <= 2) {
        try {
          final active = await FlutterOverlayWindow.isActive();
          if (active) {
            await FlutterOverlayWindow.closeOverlay();
            await Future.delayed(const Duration(milliseconds: 500));
          }

          await FlutterOverlayWindow.showOverlay(
            height: 800, // Safe physical height
            width: WindowSize.matchParent,
            alignment: OverlayAlignment.bottomCenter,
            flag: OverlayFlag.defaultFlag,
            overlayTitle: 'Konfirmasi Keamanan Aktif',
            overlayContent: 'Sigap memantau keamanan Anda.',
          );

          await Future.delayed(const Duration(milliseconds: 500));
          FlutterOverlayWindow.shareData(
              'START_OVERLAY_CHECKIN:${DateTime.now().millisecondsSinceEpoch}:$sisaWaktu');
        } catch (_) {}
      }
    }

    service.on('start_timer').listen((event) {
      if (event == null) return;
      durasiAsli = event['duration'] as int;
      sisaWaktu = durasiAsli;
      kesempatan = 0;
      stateInfo = 1;

      timer?.cancel();
      updateNotification();

      timer = Timer.periodic(const Duration(seconds: 1), (t) async {
        if (PantauAmanFlag.adaSync()) {
          PantauAmanFlag.hapus();
          sisaWaktu = durasiAsli;
          stateInfo = 1;
          kesempatan = 0;

          try {
            await FlutterOverlayWindow.closeOverlay();
          } catch (_) {}

          updateNotification();
          service.invoke('status_aman_dikonfirmasi');
        }

        if (stateInfo == 1) {
          if (sisaWaktu > 0) {
            sisaWaktu--;
            if (sisaWaktu % 10 == 0) updateNotification();
            service.invoke('tick',
                {'seconds': sisaWaktu, 'state': 1, 'kesempatan': kesempatan});
          } else {
            stateInfo = 2;
            kesempatan = 1;
            sisaWaktu = 30;
            mintaCheckIn();
          }
        } else if (stateInfo == 2) {
          if (sisaWaktu > 0) {
            sisaWaktu--;
            if (sisaWaktu % 5 == 0) updateNotification();
            service.invoke('tick',
                {'seconds': sisaWaktu, 'state': 2, 'kesempatan': kesempatan});
          } else {
            if (kesempatan < 3) {
              kesempatan++;
              sisaWaktu = (kesempatan >= 3) ? 90 : 30;
              mintaCheckIn();
            } else {
              stateInfo = 3;
              updateNotification();
              t.cancel();
              service.invoke('darurat_triggered');
              try {
                await FlutterOverlayWindow.closeOverlay();
              } catch (_) {}
            }
          }
        }
      });
    });

    service.on('stop_service').listen((event) {
      timer?.cancel();
      try {
        FlutterOverlayWindow.closeOverlay();
      } catch (_) {}
      service.stopSelf();
    });

    service.on('reset_timer').listen((event) {
      sisaWaktu = durasiAsli;
      kesempatan = 0;
      stateInfo = 1;
      updateNotification();
    });
  }
}
