import 'package:flutter/material.dart';
import 'package:sigap_mobile/features/pantau/overlay/overlay_checkin_widget.dart';

/// Entry point unik untuk system overlay.
/// Harus di-referensikan atau didaftarkan menggunakan annotation/metode
/// package flutter_overlay_window. Biasanya dideklarasikan di level top
/// (contoh: `@pragma("vm:entry-point")`).
@pragma("vm:entry-point")
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const OverlayCheckinWidget(),
    ),
  );
}
