import 'package:flutter/material.dart';
import 'package:sigap_mobile/core/constants/app_constants.dart';
import 'package:sigap_mobile/features/account/presentation/widgets/feature_cards.dart';
import 'package:sigap_mobile/features/account/presentation/widgets/guest_profile_header.dart';
import 'package:sigap_mobile/features/account/presentation/widgets/inactive_security_mode_card.dart';
import 'package:sigap_mobile/features/account/presentation/widgets/menu_tile.dart';
import 'package:sigap_mobile/features/account/presentation/widgets/section_header.dart';
import 'package:sigap_mobile/features/report_monitor/presentation/pages/report_monitor_page.dart';
import 'package:sigap_mobile/features/account/presentation/pages/account_detail_page.dart';
import 'package:sigap_mobile/features/account/presentation/pages/key_management_page.dart';
import 'package:sigap_mobile/features/account/presentation/pages/security_settings_page.dart';
import 'package:sigap_mobile/screens/login_screen.dart';

class GuestAccountPage extends StatelessWidget {
  const GuestAccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppConstants.backgroundColor,
      child: Column(
        children: [
          // Sticky Header
          GuestProfileHeader(
            onLoginPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          ),

          // Scrollable Content
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Feature Section
                  const SectionHeader(title: 'Fitur Utama'),
                  const SizedBox(height: 12),
                  const InactiveSecurityModeCard(),
                  const SizedBox(height: 16),
                  ReportMonitorButton(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ReportMonitorPage(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 32),

                  // Settings Group
                  MenuSection(
                    title: 'Pengaturan Akun',
                    tiles: [
                      MenuTile(
                        icon: Icons.manage_accounts_outlined,
                        title: 'Detail Akun',
                        subtitle: 'Daftar untuk mengisi data diri',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const AccountDetailPage(isLoggedIn: false),
                            ),
                          );
                        },
                      ),
                      MenuTile(
                        icon: Icons.vpn_key_outlined,
                        title: 'Key Management',
                        subtitle: 'Kelola kunci enkripsi laporan',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const KeyManagementPage(isLoggedIn: false),
                            ),
                          );
                        },
                      ),
                      MenuTile(
                        icon: Icons.shield_outlined,
                        title: 'Sandi & Keamanan',
                        subtitle: 'Kelola akses biometrik dan kata sandi',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const SecuritySettingsPage(isLoggedIn: false),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Info Group
                  MenuSection(
                    title: 'Info & Bantuan',
                    tiles: [
                      MenuTile(
                        icon: Icons.info_outline,
                        title: 'Tentang SIGAP',
                        subtitle:
                            'Versi ${AppConstants.appVersion}, lisensi & privasi',
                        onTap: () {},
                      ),
                      MenuTile(
                        icon: Icons.help_outline,
                        title: 'Pusat Bantuan',
                        subtitle: 'FAQ, kontak darurat & panduan',
                        onTap: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  const SizedBox(height: 24),
                  Center(
                    child: Text(
                      'SIGAP BUILD 1024 (GUEST)',
                      style: TextStyle(
                        fontSize: 10,
                        fontFamily: 'monospace',
                        color: Colors.grey.shade400,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 100), // Bottom spacer
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
