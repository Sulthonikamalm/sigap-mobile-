import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sigap_mobile/core/constants/app_constants.dart';
import 'package:sigap_mobile/features/account/presentation/pages/fingerprint_setup_page.dart';
import 'package:sigap_mobile/features/account/presentation/pages/pin_management_page.dart';

/// Halaman Sandi & Keamanan
/// Untuk mengatur kunci aplikasi, biometrik, dan password (hanya untuk user login)
class SecuritySettingsPage extends StatefulWidget {
  final bool isLoggedIn;

  const SecuritySettingsPage({super.key, this.isLoggedIn = false});

  @override
  State<SecuritySettingsPage> createState() => _SecuritySettingsPageState();
}

class _SecuritySettingsPageState extends State<SecuritySettingsPage>
    with SingleTickerProviderStateMixin {
  // State untuk expandable sections
  bool _isAppLockExpanded = false;
  bool _isKeyAccessExpanded = false;

  // State untuk toggles dan checkboxes (default: OFF)
  bool _isAppLockEnabled = false;
  bool _isBiometricEnabled = false;
  bool _isPinEnabled = false;
  String _pinType = 'same'; // 'same' atau 'custom'

  // State untuk Key Access
  bool _isKeyAccessLockEnabled = false;
  bool _isKeyBiometricEnabled = false;
  bool _isKeyPinEnabled = false;
  String _keyPinType = 'same';

  // Animation controller untuk shake (jika belum login)
  late final AnimationController _shakeController;
  bool _showLoginPrompt = false;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    if (!widget.isLoggedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _triggerShake());
    }
  }

  void _triggerShake() async {
    await Future.delayed(const Duration(milliseconds: 300));
    setState(() => _showLoginPrompt = true);
    _shakeController.forward().then((_) => _shakeController.reverse());
    HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 80));
    HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 80));
    HapticFeedback.heavyImpact();
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: widget.isLoggedIn ? _buildSecurityView() : _buildLoginPromptView(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        color: Colors.grey.shade800,
      ),
      title: Text(
        'SANDI & KEAMANAN',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade900,
          letterSpacing: 1,
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          color: Colors.grey.shade100,
          height: 1,
        ),
      ),
    );
  }

  // =========================================================================
  // VIEW: LOGIN PROMPT (Belum Login)
  // =========================================================================
  Widget _buildLoginPromptView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: Icon(Icons.shield_outlined,
                  size: 48, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 24),
            Text(
              'Akses Terbatas',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Anda harus login terlebih dahulu\nuntuk mengakses pengaturan keamanan',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14, color: Colors.grey.shade500, height: 1.5),
            ),
            const SizedBox(height: 32),
            AnimatedBuilder(
              animation: _shakeController,
              builder: (context, child) {
                final shake = Tween(begin: 0.0, end: 1.0)
                    .chain(CurveTween(curve: Curves.elasticIn))
                    .evaluate(_shakeController);
                return Transform.translate(
                  offset: Offset(10 * shake * (shake > 0.5 ? -1 : 1), 0),
                  child: child,
                );
              },
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18)),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Masuk atau Daftar',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
            if (_showLoginPrompt) ...[
              const SizedBox(height: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade100),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.info_outline,
                        size: 18, color: Colors.red.shade400),
                    const SizedBox(width: 8),
                    Text(
                      'Silakan login terlebih dahulu',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // VIEW: SECURITY SETTINGS (Sudah Login)
  // =========================================================================
  Widget _buildSecurityView() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),

          // Section: Keamanan Aplikasi
          _buildSectionHeader('Keamanan Aplikasi'),
          const SizedBox(height: 12),
          _buildAppLockSection(),
          const SizedBox(height: 24),

          // Section: Keamanan Key Management
          _buildSectionHeader('Keamanan Key Management'),
          const SizedBox(height: 12),
          _buildKeyAccessSection(),
          const SizedBox(height: 24),

          // Section: Pengaturan Sandi
          _buildSectionHeader('Pengaturan Sandi'),
          const SizedBox(height: 12),
          _buildPasswordSection(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade500,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  // =========================================================================
  // KUNCI APLIKASI SECTION
  // =========================================================================
  Widget _buildAppLockSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header (Clickable)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () =>
                  setState(() => _isAppLockExpanded = !_isAppLockExpanded),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    _buildIconContainer(Icons.lock_rounded),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kunci Aplikasi',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Opsi keamanan saat membuka aplikasi',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      turns: _isAppLockExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(Icons.keyboard_arrow_down_rounded,
                          color: Colors.grey.shade400),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Expandable Content
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _buildAppLockContent(),
            crossFadeState: _isAppLockExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  Widget _buildAppLockContent() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(top: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Column(
        children: [
          // Toggle Aktifkan Kunci
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Aktifkan Kunci Aplikasi',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                _buildSwitch(_isAppLockEnabled, (value) {
                  setState(() => _isAppLockEnabled = value);
                }),
              ],
            ),
          ),

          // Content jika enabled
          if (_isAppLockEnabled) ...[
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Metode Autentikasi
                  _buildSubHeader('Metode Autentikasi'),
                  const SizedBox(height: 12),
                  _buildAuthMethodTile(
                    icon: Icons.fingerprint_rounded,
                    title: 'Sidik Jari',
                    value: _isBiometricEnabled,
                    onChanged: (val) =>
                        setState(() => _isBiometricEnabled = val),
                  ),
                  const SizedBox(height: 10),
                  _buildAuthMethodTile(
                    icon: Icons.dialpad_rounded,
                    title: 'PIN Angka',
                    value: _isPinEnabled,
                    onChanged: (val) => setState(() => _isPinEnabled = val),
                  ),

                  // Pengaturan PIN (hanya muncul jika PIN enabled)
                  if (_isPinEnabled) ...[
                    const SizedBox(height: 24),
                    _buildSubHeader('Pengaturan PIN'),
                    const SizedBox(height: 12),
                    _buildPinTypeRadio(
                      title: 'Sama dengan Akun',
                      subtitle: 'Gunakan PIN login SIGAP utama',
                      value: 'same',
                      groupValue: _pinType,
                      onChanged: (val) => setState(() => _pinType = val!),
                    ),
                    const SizedBox(height: 8),
                    _buildPinTypeRadio(
                      title: 'PIN Khusus',
                      subtitle: 'Buat PIN berbeda untuk aplikasi ini',
                      value: 'custom',
                      groupValue: _pinType,
                      onChanged: (val) => setState(() => _pinType = val!),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // =========================================================================
  // KUNCI AKSES KEY SECTION
  // =========================================================================
  Widget _buildKeyAccessSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header (Clickable)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () =>
                  setState(() => _isKeyAccessExpanded = !_isKeyAccessExpanded),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    _buildIconContainer(Icons.vpn_key_rounded),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kunci Akses Key',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Proteksi tambahan manajemen kunci',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      turns: _isKeyAccessExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(Icons.keyboard_arrow_down_rounded,
                          color: Colors.grey.shade400),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Expandable Content
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _buildKeyAccessContent(),
            crossFadeState: _isKeyAccessExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyAccessContent() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(top: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Column(
        children: [
          // Toggle Aktifkan Kunci
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Aktifkan Kunci Akses Key',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                _buildSwitch(_isKeyAccessLockEnabled, (value) {
                  setState(() => _isKeyAccessLockEnabled = value);
                }),
              ],
            ),
          ),

          // Content jika enabled
          if (_isKeyAccessLockEnabled) ...[
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Metode Autentikasi
                  _buildSubHeader('Metode Autentikasi'),
                  const SizedBox(height: 12),
                  _buildAuthMethodTile(
                    icon: Icons.fingerprint_rounded,
                    title: 'Sidik Jari',
                    value: _isKeyBiometricEnabled,
                    onChanged: (val) =>
                        setState(() => _isKeyBiometricEnabled = val),
                  ),
                  const SizedBox(height: 10),
                  _buildAuthMethodTile(
                    icon: Icons.dialpad_rounded,
                    title: 'PIN Angka',
                    value: _isKeyPinEnabled,
                    onChanged: (val) => setState(() => _isKeyPinEnabled = val),
                  ),

                  // Pengaturan PIN (hanya muncul jika PIN enabled)
                  if (_isKeyPinEnabled) ...[
                    const SizedBox(height: 24),
                    _buildSubHeader('Pengaturan PIN'),
                    const SizedBox(height: 12),
                    _buildPinTypeRadio(
                      title: 'Sama dengan Akun',
                      subtitle: 'Gunakan PIN login SIGAP utama',
                      value: 'same',
                      groupValue: _keyPinType,
                      onChanged: (val) => setState(() => _keyPinType = val!),
                    ),
                    const SizedBox(height: 8),
                    _buildPinTypeRadio(
                      title: 'PIN Khusus',
                      subtitle: 'Buat PIN berbeda untuk key management',
                      value: 'custom',
                      groupValue: _keyPinType,
                      onChanged: (val) => setState(() => _keyPinType = val!),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // =========================================================================
  // PENGATURAN SANDI SECTION
  // =========================================================================
  Widget _buildPasswordSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildMenuTile(
            icon: Icons.password_rounded,
            title: 'Ubah Password',
            subtitle: 'Ganti kata sandi akun Anda',
            onTap: () {
              // TODO: Navigate to change password
            },
          ),
          Divider(height: 1, color: Colors.grey.shade100, indent: 68),
          _buildMenuTile(
            icon: Icons.dialpad_rounded,
            title: 'Atur PIN',
            subtitle: 'Kelola PIN akses aplikasi',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const PinManagementPage()),
              );
            },
          ),
          Divider(height: 1, color: Colors.grey.shade100, indent: 68),
          _buildMenuTile(
            icon: Icons.fingerprint_rounded,
            title: 'Atur Sidik Jari',
            subtitle: 'Verifikasi identitas dengan sidik jari',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const FingerprintSetupPage()),
              );
            },
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // REUSABLE WIDGETS
  // =========================================================================
  Widget _buildIconContainer(IconData icon) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppConstants.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, size: 22, color: AppConstants.primaryColor),
    );
  }

  Widget _buildSubHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        color: Colors.grey.shade400,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildSwitch(bool value, ValueChanged<bool> onChanged) {
    return Switch(
      value: value,
      onChanged: onChanged,
      activeColor: AppConstants.primaryColor,
      activeTrackColor: AppConstants.primaryColor.withOpacity(0.4),
      inactiveThumbColor: Colors.grey.shade300,
      inactiveTrackColor: Colors.grey.shade200,
    );
  }

  Widget _buildAuthMethodTile({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade50,
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, size: 22, color: Colors.grey.shade400),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Checkbox(
            value: value,
            onChanged: (val) => onChanged(val ?? false),
            activeColor: AppConstants.primaryColor,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
        ],
      ),
    );
  }

  Widget _buildPinTypeRadio({
    required String title,
    required String subtitle,
    required String value,
    required String groupValue,
    required ValueChanged<String?> onChanged,
  }) {
    final isSelected = value == groupValue;
    return Material(
      color: isSelected ? Colors.white : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => onChanged(value),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? AppConstants.primaryColor.withOpacity(0.3)
                  : Colors.transparent,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.grey.shade50,
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Radio<String>(
                value: value,
                groupValue: groupValue,
                onChanged: onChanged,
                activeColor: AppConstants.primaryColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade900,
                      ),
                    ),
                    Text(
                      subtitle,
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _buildIconContainer(icon),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade900,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}
