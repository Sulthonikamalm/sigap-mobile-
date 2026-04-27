import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sigap_mobile/core/constants/app_constants.dart';
import 'package:sigap_mobile/features/auth/presentation/pages/daftar_page.dart';
import 'package:sigap_mobile/features/auth/presentation/widgets/kolom_input_auth.dart';
import 'package:sigap_mobile/features/auth/presentation/widgets/tombol_masuk_sosial.dart';
import 'package:sigap_mobile/features/auth/presentation/widgets/komponen_bersama_auth.dart';
import 'package:sigap_mobile/features/auth/presentation/widgets/link_mode_pengembangan.dart';

/// Halaman masuk (login) — gerbang utama menuju SIGAP.
///
/// Alur navigasi:
///   Input email/NIM + sandi → [belum terhubung backend]
///   Google / Microsoft      → [belum terhubung OAuth]
///   Mode Pengembangan       → AuthCheckScreen (bypass cepat)
///   Belum punya akun?       → DaftarPage
class MasukPage extends StatefulWidget {
  const MasukPage({super.key});

  @override
  State<MasukPage> createState() => _MasukPageState();
}

class _MasukPageState extends State<MasukPage>
    with SingleTickerProviderStateMixin {
  final _kontrolerEmail = TextEditingController();
  final _kontrolerSandi = TextEditingController();
  final _kunciForm = GlobalKey<FormState>();
  bool _sedangMemuat = false;

  late final AnimationController _kontrolerAnimasi;
  late final Animation<double> _animasiMasuk;

  @override
  void initState() {
    super.initState();
    _kontrolerAnimasi = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _animasiMasuk =
        CurvedAnimation(parent: _kontrolerAnimasi, curve: Curves.easeOutCubic);
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) _kontrolerAnimasi.forward();
    });
  }

  @override
  void dispose() {
    _kontrolerEmail.dispose();
    _kontrolerSandi.dispose();
    _kontrolerAnimasi.dispose();
    super.dispose();
  }

  // ─── Handler ────────────────────────────────────────────────

  void _tanganiMasuk() {
    if (!_kunciForm.currentState!.validate()) return;
    setState(() => _sedangMemuat = true);
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      setState(() => _sedangMemuat = false);
      _tampilkanInfo('Fitur ini dalam pengembangan.\n'
          'Gunakan Mode Pengembangan untuk masuk.');
    });
  }

  void _tampilkanInfo(String pesan) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Row(children: [
          const Icon(Icons.info_outline_rounded, color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(pesan, style: GoogleFonts.poppins(fontSize: 12.5)),
          ),
        ]),
        backgroundColor: AppConstants.primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ));
  }

  void _keDaftar() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const DaftarPage(),
        transitionsBuilder: (_, a, __, c) {
          final kurva = CurvedAnimation(parent: a, curve: Curves.easeOutCubic);
          return SlideTransition(
            position: Tween(begin: const Offset(1, 0), end: Offset.zero)
                .animate(kurva),
            child: c,
          );
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  // ─── Build ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: FadeTransition(
          opacity: _animasiMasuk,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _kunciForm,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 48),
                  _bangunHeader(),
                  const SizedBox(height: 40),
                  KolomInputAuth(
                    kontroler: _kontrolerEmail,
                    label: 'Email atau NIM',
                    petunjuk: '1202230023 atau nama@student...',
                    ikonAwalan: Icons.alternate_email_rounded,
                    tipeInput: TextInputType.emailAddress,
                    petunjukIsiOtomatis: const [AutofillHints.email],
                    validasi: (v) => (v == null || v.trim().isEmpty)
                        ? 'Email atau NIM wajib diisi'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  KolomInputAuth(
                    kontroler: _kontrolerSandi,
                    label: 'Kata Sandi',
                    petunjuk: 'Masukkan kata sandi',
                    adalahSandi: true,
                    aksiInput: TextInputAction.done,
                    petunjukIsiOtomatis: const [AutofillHints.password],
                    validasi: (v) => (v == null || v.isEmpty)
                        ? 'Kata sandi wajib diisi'
                        : null,
                  ),
                  const SizedBox(height: 8),
                  _bangunLinkLupaSandi(),
                  const SizedBox(height: 24),
                  TombolUtamaAuth(
                    label: 'Masuk',
                    sedangMemuat: _sedangMemuat,
                    onTekan: _tanganiMasuk,
                  ),
                  const SizedBox(height: 28),
                  const DividerAuth(teks: 'atau masuk dengan'),
                  const SizedBox(height: 20),
                  TombolMasukSosial(
                    onKetukGoogle: () =>
                        _tampilkanInfo('Google Sign-In dalam pengembangan.'),
                    onKetukMicrosoft: () =>
                        _tampilkanInfo('Microsoft Sign-In dalam pengembangan.'),
                  ),
                  const SizedBox(height: 36),
                  _bangunLinkDaftar(),
                  const SizedBox(height: 20),
                  const LinkModePengembangan(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Komponen UI ────────────────────────────────────────────

  Widget _bangunHeader() {
    return Column(children: [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppConstants.primaryColor.withValues(alpha: 0.08),
          shape: BoxShape.circle,
        ),
        child: Image.asset(
          'assets/images/logo_sigap.png',
          height: 52,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Icon(Icons.shield_rounded,
              size: 52, color: AppConstants.primaryColor),
        ),
      ),
      const SizedBox(height: 28),
      Text('Selamat Datang',
          style: GoogleFonts.poppins(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: AppConstants.textDark,
              letterSpacing: -0.3)),
      const SizedBox(height: 8),
      Text('Masuk untuk mengakses layanan\nSIGAP PPKPT',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
              fontSize: 14, color: AppConstants.textSecondary, height: 1.5)),
    ]);
  }

  Widget _bangunLinkLupaSandi() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () => _tampilkanInfo('Reset password belum tersedia.'),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text('Lupa kata sandi?',
            style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppConstants.primaryColor)),
      ),
    );
  }

  Widget _bangunLinkDaftar() {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text('Belum punya akun? ',
          style: GoogleFonts.poppins(
              fontSize: 14, color: AppConstants.textSecondary)),
      GestureDetector(
        onTap: _keDaftar,
        child: Text('Daftar',
            style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppConstants.primaryColor)),
      ),
    ]);
  }
}
