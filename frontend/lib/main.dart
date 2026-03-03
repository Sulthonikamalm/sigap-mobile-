import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sigap_mobile/core/constants/app_constants.dart';
import 'package:sigap_mobile/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:sigap_mobile/features/pantau/overlay/overlay_entry_point.dart';
import 'package:sigap_mobile/features/pantau/services/pantau_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  // WAJIB di-await SEBELUM runApp — background service harus terkonfigurasi
  // agar channel invoke/on antara UI dan service isolate bisa berfungsi.
  await PantauNotificationService.initializeService();
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
      home: const OnboardingPage(),
    );
  }
}
