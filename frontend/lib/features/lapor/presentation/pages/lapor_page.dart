import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sigap_mobile/core/constants/app_constants.dart';
import 'package:sigap_mobile/features/lapor/presentation/widgets/emergency_radar_widget.dart';
import 'package:sigap_mobile/features/lapor/presentation/widgets/countdown_ring_painter.dart';

class LaporPage extends StatefulWidget {
  const LaporPage({super.key});

  @override
  State<LaporPage> createState() => _LaporPageState();
}

class _LaporPageState extends State<LaporPage> with TickerProviderStateMixin {
  // STATE MACHINE
  // 0 = Countdown (Pre-SOS)
  // 1 = Active (Sistem Aktif/Sending)
  int _state = 0;

  // Timer & Progress
  Timer? _timer;
  late AnimationController _progressController;
  late Animation<double> _pulseAnimation;
  late AnimationController _pulseController;

  static const int _countdownSeconds = 3;
  int _currentSecond = _countdownSeconds;

  @override
  void initState() {
    super.initState();

    // Controller untuk Progress Ring (3 detik dari 1.0 ke 0.0)
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: _countdownSeconds),
    );

    // Controller untuk visual detak jantung (Pulse Background)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _startCountdown();
  }

  void _startCountdown() {
    _progressController.reverse(from: 1.0);
    _pulseController.repeat(reverse: true);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_currentSecond > 1) {
        setState(() {
          _currentSecond--;
        });
        HapticFeedback.mediumImpact();
      } else {
        _activateEmergencyProtocol();
      }
    });
  }

  void _activateEmergencyProtocol() {
    _timer?.cancel();
    HapticFeedback.heavyImpact();

    if (mounted) {
      setState(() {
        _state = 1;
      });
      _pulseController.stop();
      _pulseController.duration = const Duration(milliseconds: 500);
      _pulseController.repeat(reverse: true);
    }
  }

  void _handleCancel() {
    HapticFeedback.selectionClick();
    _timer?.cancel();
    _progressController.stop();
    Navigator.of(context).pop();
  }

  void _handleStopFunctions() {
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Sistem Darurat Dinonaktifkan',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Color(0xFF333333),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(20),
        duration: Duration(seconds: 2),
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _progressController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color activeColor =
        _state == 0 ? AppConstants.primaryColor : AppConstants.urgentColor;

    // Menggunakan PopScope (pengganti WillPopScope yang deprecated)
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),

                  // --- STATUS HEADER ---
                  _buildStatusHeader(activeColor),

                  const Spacer(flex: 1),

                  // --- VISUAL CENTER HUB ---
                  _buildVisualHub(activeColor),

                  const SizedBox(height: 56),

                  // --- CONTEXTUAL INFO ---
                  _buildContextualInfo(activeColor),

                  const Spacer(flex: 3),

                  // --- ACTION BUTTON ---
                  _buildActionButton(activeColor),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildStatusHeader(Color activeColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: activeColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: activeColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: activeColor,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            _state == 0 ? "SIAGA DARURAT" : "TRANSMISI AKTIF",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: activeColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisualHub(Color activeColor) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // 1. Radar Animation Background
        EmergencyRadarWidget(
          isActive: true,
          color: activeColor,
        ),

        // 2. Countdown Progress Ring (Custom Painter)
        SizedBox(
          width: 180,
          height: 180,
          child: AnimatedBuilder(
            animation: _progressController,
            builder: (context, child) {
              return CustomPaint(
                painter: CountdownRingPainter(
                  progress: _state == 0 ? _progressController.value : 1.0,
                  color: activeColor,
                  isPulse: _state == 1,
                ),
              );
            },
          ),
        ),

        // 3. Main Center Circle
        Transform.scale(
          scale: _state == 1 ? _pulseAnimation.value : 1.0,
          child: Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: activeColor.withValues(alpha: 0.2),
                  blurRadius: 40,
                  offset: const Offset(0, 10),
                  spreadRadius: 5,
                ),
              ],
              border: Border.all(
                color: activeColor.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: Center(
              child: _state == 0
                  ? Text(
                      "$_currentSecond",
                      style: TextStyle(
                        fontSize: 64,
                        fontWeight: FontWeight.w300,
                        color: activeColor,
                      ),
                    )
                  : Icon(
                      Icons.wifi_tethering,
                      size: 64,
                      color: activeColor,
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContextualInfo(Color activeColor) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: _state == 0
          ? Column(
              key: const ValueKey(0),
              children: [
                const Text(
                  "Mengirim Sinyal Darurat...",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Tekan BATALKAN jika tidak sengaja.",
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            )
          : Column(
              key: const ValueKey(1),
              children: [
                Text(
                  "MENGHUBUNGI BANTUAN",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: activeColor,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.location_on,
                        size: 14, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(
                      "Lokasi Terkunci • Audio Merekam",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildActionButton(Color activeColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: SizedBox(
        width: double.infinity,
        height: 58,
        child: ElevatedButton(
          onPressed: _state == 0 ? _handleCancel : _handleStopFunctions,
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: Colors.white,
            foregroundColor: activeColor,
            side: BorderSide(
              color: activeColor.withValues(alpha: 0.5),
              width: 1.5,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: Text(
            _state == 0 ? "Batalkan" : "Matikan Sistem",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              color: activeColor,
            ),
          ),
        ),
      ),
    );
  }
}
