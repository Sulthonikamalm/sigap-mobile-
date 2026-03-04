import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sigap_mobile/core/constants/app_constants.dart';
import 'package:sigap_mobile/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:sigap_mobile/features/pantau/overlay/overlay_entry_point.dart';
import 'package:sigap_mobile/features/pantau/services/pantau_notification_service.dart';
import 'package:sigap_mobile/features/pantau/services/pantau_service.dart';
import 'package:sigap_mobile/features/pantau/presentation/pages/trigger_sent_page.dart';
import 'package:sigap_mobile/features/lapor/services/emergency_notification_handler.dart';

/// Instance global handler darurat — bisa diakses dari mana saja
/// (notification callback, background service, dsb).
late final EmergencyNotificationHandler emergencyHandler;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  // WAJIB di-await SEBELUM runApp — background service harus terkonfigurasi
  // agar channel invoke/on antara UI dan service isolate bisa berfungsi.
  await PantauNotificationService.initializeService();

  // Daftarkan juga channel Sirine untuk HP Penolong
  await EmergencyNotificationHandler.initializeResponderChannel();

  // Singleton instance untuk State Management isolasi UI dari Timer
  PantauService.instance.initialize();

  // Inisialisasi handler darurat — pakai navigatorKey yang sama
  // agar bisa navigasi tanpa context dari mana saja
  emergencyHandler = EmergencyNotificationHandler(
    navigatorKey: PantauService.instance.navigatorKey,
  );

  runApp(const SigapApp());
}

// Global scope registration for Android Service (flutter_overlay_window)
@pragma("vm:entry-point")
void overlayMain() {
  runOverlayMain();
}

class SigapApp extends StatelessWidget {
  const SigapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sigap',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppConstants.primaryColor,
          primary: AppConstants.primaryColor,
          surface: Colors.white,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: AppConstants.backgroundColor,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
      ),
      navigatorKey: PantauService
          .instance.navigatorKey, // Injeksi key untuk navigasi context-less
      home: const OnboardingPage(),
      routes: {
        '/trigger_sent': (context) => const TriggerSentPage(),
      },
    );
  }
}
