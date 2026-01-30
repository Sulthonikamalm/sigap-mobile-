import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sigap_mobile/core/constants/app_constants.dart';

/// Halaman Pengaturan Sidik Jari
/// Untuk mendaftarkan dan mengelola sidik jari pengguna
class FingerprintSetupPage extends StatefulWidget {
  const FingerprintSetupPage({super.key});

  @override
  State<FingerprintSetupPage> createState() => _FingerprintSetupPageState();
}

class _FingerprintSetupPageState extends State<FingerprintSetupPage>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final AnimationController _confettiController;

  // States: idle, scanning, success, failed
  String _currentState = 'idle';

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _confettiController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _startScanning() {
    HapticFeedback.mediumImpact();
    setState(() => _currentState = 'scanning');

    // Simulasi scanning (random success/failed untuk demo)
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        // Random hasil untuk demo, bisa diganti logic sebenarnya
        final success = Random().nextBool();
        if (success) {
          _onSuccess();
        } else {
          _onFailed();
        }
      }
    });
  }

  void _onSuccess() {
    HapticFeedback.heavyImpact();
    setState(() => _currentState = 'success');
    _confettiController.forward();
  }

  void _onFailed() {
    HapticFeedback.vibrate();
    setState(() => _currentState = 'failed');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(child: _buildMainContent()),
              _buildFooter(),
            ],
          ),
          // Confetti overlay
          if (_currentState == 'success')
            ConfettiOverlay(controller: _confettiController),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      leading: _currentState == 'success'
          ? const SizedBox.shrink()
          : IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(
                Icons.arrow_back_rounded,
                size: 24,
                color: _currentState == 'failed'
                    ? Colors.red.shade400
                    : Colors.grey.shade800,
              ),
            ),
      title: Text(
        'SIDIK JARI',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade900,
          letterSpacing: 2,
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon based on state
            _buildStateIcon(),
            const SizedBox(height: 40),
            // Title & Description
            _buildStateContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildStateIcon() {
    switch (_currentState) {
      case 'success':
        return _SuccessIcon();
      case 'failed':
        return _FailedIcon(pulseAnimation: _pulseController);
      default:
        return _FingerprintIcon(
          pulseAnimation: _pulseController,
          isScanning: _currentState == 'scanning',
        );
    }
  }

  Widget _buildStateContent() {
    switch (_currentState) {
      case 'scanning':
        return _buildTextContent(
          title: 'Memindai...',
          subtitle: 'Tahan jari Anda pada sensor',
        );
      case 'success':
        return _buildTextContent(
          title: 'Sidik Jari Berhasil Terdaftar',
          subtitle:
              'Otentikasi biometrik Anda kini aktif untuk mengamankan data privat.',
        );
      case 'failed':
        return _buildTextContent(
          title: 'Pemindaian Gagal',
          subtitle:
              'Sensor tidak dapat mengenali jari Anda. Pastikan sensor bersih dan coba lagi.',
          isError: true,
        );
      default:
        return _buildTextContent(
          title: 'Daftarkan Sidik Jari',
          subtitle:
              'Gunakan otentikasi biometrik untuk akses cepat dan aman ke data privat Anda',
        );
    }
  }

  Widget _buildTextContent({
    required String title,
    required String subtitle,
    bool isError = false,
  }) {
    return Column(
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade900,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            color: Colors.grey.shade500,
            height: 1.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(32, 16, 32, 48),
      child: Column(
        children: [
          if (_currentState == 'success') ...[
            // Success: Selesai button
            _buildPrimaryButton(
              label: 'Selesai',
              onTap: () => Navigator.pop(context),
              isPrimary: true,
            ),
          ] else if (_currentState == 'failed') ...[
            // Failed: Coba Lagi button
            _buildPrimaryButton(
              label: 'Coba Lagi',
              icon: Icons.refresh_rounded,
              onTap: _startScanning,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Gunakan Metode Lain',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade400,
                ),
              ),
            ),
          ] else ...[
            // Idle/Scanning: Mulai Pemindaian
            _buildScanButton(),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Nanti Saja',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade400,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildScanButton() {
    final isScanning = _currentState == 'scanning';
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: isScanning ? null : _startScanning,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isScanning
                    ? AppConstants.primaryColor.withOpacity(0.5)
                    : Colors.grey.shade200,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppConstants.primaryColor.withOpacity(0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isScanning) ...[
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation(AppConstants.primaryColor),
                    ),
                  ),
                ] else ...[
                  Icon(Icons.fingerprint_rounded,
                      color: AppConstants.primaryColor, size: 22),
                ],
                const SizedBox(width: 10),
                Text(
                  isScanning ? 'Memindai...' : 'Mulai Pemindaian',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade900,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required VoidCallback onTap,
    IconData? icon,
    bool isPrimary = false,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary
              ? AppConstants.primaryColor
              : AppConstants.primaryColor.withOpacity(0.6),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
          shadowColor: AppConstants.primaryColor.withOpacity(0.3),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// WIDGET: FINGERPRINT ICON
// =============================================================================
class _FingerprintIcon extends StatelessWidget {
  final AnimationController pulseAnimation;
  final bool isScanning;

  const _FingerprintIcon({
    required this.pulseAnimation,
    required this.isScanning,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      height: 180,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer Pulse Ring
          if (isScanning)
            AnimatedBuilder(
              animation: pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: 1.0 + (pulseAnimation.value * 0.2),
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppConstants.primaryColor
                            .withOpacity(0.3 - (pulseAnimation.value * 0.2)),
                        width: 2,
                      ),
                    ),
                  ),
                );
              },
            ),
          // Glow Background
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppConstants.primaryColor
                      .withOpacity(isScanning ? 0.25 : 0.1),
                  blurRadius: 40,
                  spreadRadius: 10,
                ),
              ],
            ),
          ),
          // Main Circle
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: Colors.grey.shade200,
                    blurRadius: 24,
                    offset: const Offset(12, 12)),
                const BoxShadow(
                    color: Colors.white,
                    blurRadius: 24,
                    offset: Offset(-12, -12)),
              ],
            ),
            child: Icon(
              Icons.fingerprint_rounded,
              size: 96,
              color: isScanning
                  ? AppConstants.primaryColor
                  : AppConstants.primaryColor.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// WIDGET: SUCCESS ICON
// =============================================================================
class _SuccessIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      height: 180,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer Ring
          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.green.shade100, width: 2),
            ),
          ),
          // Glow
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.15),
                  blurRadius: 40,
                  spreadRadius: 10,
                ),
              ],
            ),
          ),
          // Main Circle
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: Colors.grey.shade200,
                    blurRadius: 24,
                    offset: const Offset(12, 12)),
                const BoxShadow(
                    color: Colors.white,
                    blurRadius: 24,
                    offset: Offset(-12, -12)),
              ],
            ),
            child: Icon(Icons.check_circle_outline_rounded,
                size: 80, color: Colors.green.shade500),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// WIDGET: FAILED ICON
// =============================================================================
class _FailedIcon extends StatelessWidget {
  final AnimationController pulseAnimation;

  const _FailedIcon({required this.pulseAnimation});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      height: 180,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Pulse Ring
          AnimatedBuilder(
            animation: pulseAnimation,
            builder: (context, child) {
              return Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.red.shade200
                        .withOpacity(0.5 + (pulseAnimation.value * 0.3)),
                    width: 2,
                  ),
                ),
              );
            },
          ),
          // Glow
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.12),
                  blurRadius: 40,
                  spreadRadius: 10,
                ),
              ],
            ),
          ),
          // Main Circle
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: Colors.grey.shade200,
                    blurRadius: 24,
                    offset: const Offset(12, 12)),
                const BoxShadow(
                    color: Colors.white,
                    blurRadius: 24,
                    offset: Offset(-12, -12)),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(Icons.fingerprint_rounded,
                    size: 80, color: Colors.red.shade400),
                Positioned(
                  right: 35,
                  bottom: 35,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                        color: Colors.white, shape: BoxShape.circle),
                    child: Icon(Icons.error_rounded,
                        size: 28, color: Colors.red.shade500),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// WIDGET: CONFETTI OVERLAY (Subtle, not too flashy)
// =============================================================================
class ConfettiOverlay extends StatelessWidget {
  final AnimationController controller;

  const ConfettiOverlay({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        if (controller.value == 0) return const SizedBox.shrink();
        return IgnorePointer(
          child: CustomPaint(
            painter: _ConfettiPainter(
              progress: controller.value,
              colors: [
                AppConstants.primaryColor,
                Colors.green.shade400,
                Colors.amber.shade400,
                Colors.blue.shade300,
              ],
            ),
            size: MediaQuery.of(context).size,
          ),
        );
      },
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final double progress;
  final List<Color> colors;
  final List<_ConfettiParticle> particles;

  _ConfettiPainter({required this.progress, required this.colors})
      : particles = List.generate(25, (i) => _ConfettiParticle(i, colors));

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      final paint = Paint()
        ..color = particle.color.withOpacity((1 - progress) * 0.8)
        ..style = PaintingStyle.fill;

      final x = particle.startX * size.width;
      final y = particle.startY * size.height +
          (progress * size.height * particle.speed);
      final rotation = progress * particle.rotation * 2 * pi;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation);

      if (particle.isCircle) {
        canvas.drawCircle(Offset.zero, particle.size, paint);
      } else {
        canvas.drawRect(
          Rect.fromCenter(
              center: Offset.zero,
              width: particle.size,
              height: particle.size * 0.6),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _ConfettiParticle {
  final double startX;
  final double startY;
  final double speed;
  final double rotation;
  final double size;
  final Color color;
  final bool isCircle;

  _ConfettiParticle(int index, List<Color> colors)
      : startX = Random(index).nextDouble(),
        startY = Random(index * 2).nextDouble() * 0.3 - 0.3,
        speed = 0.3 + Random(index * 3).nextDouble() * 0.5,
        rotation = Random(index * 4).nextDouble() * 4,
        size = 4 + Random(index * 5).nextDouble() * 6,
        color = colors[Random(index * 6).nextInt(colors.length)],
        isCircle = Random(index * 7).nextBool();
}
