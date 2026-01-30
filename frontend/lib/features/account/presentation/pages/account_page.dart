import 'package:flutter/material.dart';
import 'package:sigap_mobile/core/constants/app_constants.dart';
import 'package:sigap_mobile/features/account/presentation/widgets/feature_cards.dart';
import 'package:sigap_mobile/features/account/presentation/widgets/menu_tile.dart';
import 'package:sigap_mobile/features/account/presentation/widgets/profile_header.dart';
import 'package:sigap_mobile/features/report_monitor/presentation/pages/report_monitor_page.dart';
import 'package:sigap_mobile/features/account/presentation/pages/account_detail_page.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppConstants.backgroundColor,
      child: Column(
        children: [
          // Sticky Header
          ProfileHeader(
            name: 'Sulthonika Mahfudz',
            institution: 'Telkom University',
            role: 'Mahasiswa',
            imageUrl:
                'https://lh3.googleusercontent.com/aida-public/AB6AXuB6n1llJuDcsVQPo9Si_GXl8O7Dof1v2P5JP_VH1LeJzLcCmmBaNqCnlTSgN8-3MFOEoc-bhyFXdteifipfbAsXNrSMh36xM4t8gmhU1z859pvzrM3D8-kDHrBvY-xTueBVyVVxkFbeucG3oakphvKS5w9lEVyRVx-RfQGay3OnJgz8oj9N3asxVFmj-iP3opXztRayLD-l2TiVM8xGPGLbcTSOxRAJerm-_KV2wzgPwNSo4hfGeHp49KTxuWgJmPZRsYqEjReT3MDn',
            onEditPressed: () {
              // TODO: Implement Edit Profile
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
                  _buildSectionHeader('Fitur Utama'),
                  const SizedBox(height: 12),
                  SecurityModeCard(
                    initialValue: true,
                    onChanged: (value) {
                      // TODO: Handle Toggle
                    },
                  ),
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
                        subtitle: 'Edit data diri, sandi & keamanan',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const AccountDetailPage(isLoggedIn: true),
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

                  // Logout Button
                  _buildLogoutButton(),

                  const SizedBox(height: 24),
                  Center(
                    child: Text(
                      'SIGAP BUILD 1024',
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

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade400,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppConstants.urgentColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: AppConstants.urgentColor.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // TODO: Implement Logout
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.logout,
                  color: AppConstants.urgentColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Keluar dari Akun',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.urgentColor,
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
