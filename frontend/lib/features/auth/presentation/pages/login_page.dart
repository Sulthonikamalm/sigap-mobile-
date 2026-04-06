import 'package:flutter/material.dart';
import 'package:sigap_mobile/core/constants/app_constants.dart';
import 'package:sigap_mobile/features/home/presentation/pages/home_page.dart';
import 'package:sigap_mobile/features/satgas_lite/presentation/pages/admin_lite_page.dart';
import 'package:sigap_mobile/features/satgas_lite/presentation/pages/psikolog_lite_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    setState(() => _isLoading = true);

    // Simulasi Server Delay
    await Future.delayed(const Duration(seconds: 1));
    
    final email = _emailController.text.toLowerCase();

    // ---------------------------------------------------------
    // LANGKAH 6: POLANTAS LOGIN (LOGIKA ROUTING)
    // ---------------------------------------------------------
    
    // Mock response parsing based on typed email to demonstrate routing
    String role = 'mahasiswa';
    String userName = 'Mahasiswa Budi';

    if (email.contains('admin')) {
      role = 'admin';
      userName = 'Sulis (Admin)';
    } else if (email.contains('psikolog')) {
      role = 'psikolog';
      userName = 'Dr. Andi';
    }

    setState(() => _isLoading = false);

    // Percabangan Routing berdasarkan Role ("Polantas Routing")
    if (!mounted) return;
    
    if (role == 'mahasiswa') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage(isGuest: false)),
      );
    } else if (role == 'admin') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => AdminLitePage(userName: userName),
        ),
      );
    } else if (role == 'psikolog') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PsikologLitePage(userName: userName),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.shield_outlined, size: 80, color: AppConstants.primaryColor),
                const SizedBox(height: 24),
                const Text(
                  'SIGAP LOGIN',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Silakan login untuk melanjutkan',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppConstants.textSecondary),
                ),
                const SizedBox(height: 40),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    hintText: 'Ketik "admin" atau "psikolog" untuk test',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.lock_outline),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _isLoading ? null : _handleLogin,
                    child: _isLoading 
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Masuk', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
