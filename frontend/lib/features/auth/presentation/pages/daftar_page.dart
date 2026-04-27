import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sigap_mobile/core/constants/app_constants.dart';
import 'package:sigap_mobile/features/auth/data/konstanta_auth.dart';
import 'package:sigap_mobile/features/auth/presentation/widgets/kolom_input_auth.dart';
import 'package:sigap_mobile/features/auth/presentation/widgets/tombol_masuk_sosial.dart';
import 'package:sigap_mobile/features/auth/presentation/widgets/pemilih_peran.dart';
import 'package:sigap_mobile/features/auth/presentation/widgets/dropdown_prodi.dart';
import 'package:sigap_mobile/features/auth/presentation/widgets/komponen_bersama_auth.dart';
import 'package:sigap_mobile/features/auth/presentation/widgets/link_mode_pengembangan.dart';

/// Halaman pendaftaran akun baru — field berubah sesuai peran.
class DaftarPage extends StatefulWidget {
  const DaftarPage({super.key});
  @override
  State<DaftarPage> createState() => _DaftarPageState();
}

class _DaftarPageState extends State<DaftarPage>
    with SingleTickerProviderStateMixin {
  final _kNama = TextEditingController();
  final _kIdentitas = TextEditingController();
  final _kEmail = TextEditingController();
  final _kHP = TextEditingController();
  final _kUnitKerja = TextEditingController();
  final _kSandi = TextEditingController();
  final _kKonfirmasi = TextEditingController();
  final _kunciForm = GlobalKey<FormState>();

  bool _sedangMemuat = false;
  PeranPendaftaran _peran = PeranPendaftaran.mahasiswa;
  String? _prodiTerpilih;

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
    for (final k in [
      _kNama,
      _kIdentitas,
      _kEmail,
      _kHP,
      _kUnitKerja,
      _kSandi,
      _kKonfirmasi
    ]) {
      k.dispose();
    }
    _kontrolerAnimasi.dispose();
    super.dispose();
  }

  // ─── Handler ────────────────────────────────────────────────

  void _tanganiDaftar() {
    if (!_kunciForm.currentState!.validate()) return;
    if (_peran.perluProdi && _prodiTerpilih == null) {
      _tampilkanPesan('Silakan pilih Program Studi', isError: true);
      return;
    }
    setState(() => _sedangMemuat = true);
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      setState(() => _sedangMemuat = false);
      _tampilkanPesan('Pendaftaran belum terhubung ke server.\n'
          'Gunakan Mode Pengembangan untuk masuk.');
    });
  }

  void _gantiPeran(PeranPendaftaran baru) {
    setState(() {
      _peran = baru;
      _kIdentitas.clear();
      _prodiTerpilih = null;
      _kUnitKerja.clear();
    });
  }

  void _tampilkanPesan(String pesan, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Row(children: [
          Icon(
              isError
                  ? Icons.warning_amber_rounded
                  : Icons.info_outline_rounded,
              color: Colors.white,
              size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(pesan, style: GoogleFonts.poppins(fontSize: 12.5)),
          ),
        ]),
        backgroundColor:
            isError ? AppConstants.errorColor : AppConstants.primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ));
  }

  // ─── Build ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded,
              color: AppConstants.textDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
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
                  const SizedBox(height: 8),
                  _bangunHeader(),
                  const SizedBox(height: 28),
                  PemilihPeran(
                      peranTerpilih: _peran, onPeranBerubah: _gantiPeran),
                  const SizedBox(height: 24),
                  ..._bangunFieldFormulir(),
                  const SizedBox(height: 28),
                  TombolUtamaAuth(
                      label: 'Daftar',
                      sedangMemuat: _sedangMemuat,
                      onTekan: _tanganiDaftar),
                  const SizedBox(height: 24),
                  const DividerAuth(teks: 'atau daftar dengan'),
                  const SizedBox(height: 18),
                  TombolMasukSosial(
                    onKetukGoogle: () =>
                        _tampilkanPesan('Google Sign-Up dalam pengembangan.'),
                    onKetukMicrosoft: () => _tampilkanPesan(
                        'Microsoft Sign-Up dalam pengembangan.'),
                  ),
                  const SizedBox(height: 32),
                  _bangunLinkMasuk(),
                  const SizedBox(height: 16),
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
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Buat Akun Baru',
          style: GoogleFonts.poppins(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: AppConstants.textDark,
              letterSpacing: -0.3)),
      const SizedBox(height: 8),
      Text(
          'Daftar untuk mengakses layanan pelaporan\n'
          'dan perlindungan SIGAP PPKPT.',
          style: GoogleFonts.poppins(
              fontSize: 14, color: AppConstants.textSecondary, height: 1.5)),
    ]);
  }

  List<Widget> _bangunFieldFormulir() {
    const jarak = SizedBox(height: 14);
    return [
      KolomInputAuth(
          kontroler: _kNama,
          label: 'Nama Lengkap',
          petunjuk: 'Sesuai identitas resmi',
          ikonAwalan: Icons.person_outline_rounded,
          tipeInput: TextInputType.name,
          petunjukIsiOtomatis: const [AutofillHints.name],
          validasi: (v) =>
              (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null),
      jarak,
      KolomInputAuth(
          kontroler: _kIdentitas,
          label: _peran.labelIdentitas,
          petunjuk: _peran.contohIdentitas,
          ikonAwalan: Icons.badge_outlined,
          tipeInput: TextInputType.number,
          validasi: (v) => (v == null || v.trim().isEmpty)
              ? '${_peran.labelIdentitas} wajib diisi'
              : null),
      jarak,
      KolomInputAuth(
          kontroler: _kEmail,
          label: 'Email Institusi',
          petunjuk: _peran.petunjukEmail,
          ikonAwalan: Icons.alternate_email_rounded,
          tipeInput: TextInputType.emailAddress,
          petunjukIsiOtomatis: const [AutofillHints.email],
          validasi: (v) {
            if (v == null || v.trim().isEmpty) return 'Email wajib diisi';
            if (!v.contains('@')) return 'Format email tidak valid';
            return null;
          }),
      jarak,
      KolomInputAuth(
          kontroler: _kHP,
          label: 'Nomor HP',
          petunjuk: '08xxxxxxxxxx',
          ikonAwalan: Icons.phone_outlined,
          tipeInput: TextInputType.phone,
          petunjukIsiOtomatis: const [AutofillHints.telephoneNumber],
          validasi: (v) =>
              (v == null || v.trim().isEmpty) ? 'Nomor HP wajib diisi' : null),
      jarak,
      if (_peran.perluProdi)
        DropdownProdi(
            nilaiTerpilih: _prodiTerpilih,
            onBerubah: (v) => setState(() => _prodiTerpilih = v))
      else
        KolomInputAuth(
            kontroler: _kUnitKerja,
            label: 'Unit Kerja',
            petunjuk: 'Contoh: Biro Akademik',
            ikonAwalan: Icons.business_rounded,
            validasi: (v) => (v == null || v.trim().isEmpty)
                ? 'Unit Kerja wajib diisi'
                : null),
      jarak,
      KolomInputAuth(
          kontroler: _kSandi,
          label: 'Kata Sandi',
          petunjuk: 'Minimal 8 karakter',
          adalahSandi: true,
          petunjukIsiOtomatis: const [AutofillHints.newPassword],
          validasi: (v) {
            if (v == null || v.isEmpty) return 'Kata sandi wajib diisi';
            if (v.length < 8) return 'Minimal 8 karakter';
            return null;
          }),
      jarak,
      KolomInputAuth(
          kontroler: _kKonfirmasi,
          label: 'Konfirmasi Kata Sandi',
          petunjuk: 'Ulangi kata sandi',
          adalahSandi: true,
          aksiInput: TextInputAction.done,
          validasi: (v) {
            if (v == null || v.isEmpty) return 'Konfirmasi wajib diisi';
            if (v != _kSandi.text) return 'Kata sandi tidak cocok';
            return null;
          }),
    ];
  }

  Widget _bangunLinkMasuk() {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text('Sudah punya akun? ',
          style: GoogleFonts.poppins(
              fontSize: 14, color: AppConstants.textSecondary)),
      GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Text('Masuk',
            style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppConstants.primaryColor)),
      ),
    ]);
  }
}
