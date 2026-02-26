import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sigap_mobile/core/constants/app_constants.dart';
import 'package:sigap_mobile/features/pantau/data/kontak_darurat_data.dart';

/// Layar Aman Pasca Trigger.
/// Didesain menggunakan prinsip Trauma-Informed Care: tenang, memvalidasi, jelas.
class AmanPascaTriggerPage extends StatefulWidget {
  const AmanPascaTriggerPage({super.key});

  @override
  State<AmanPascaTriggerPage> createState() => _AmanPascaTriggerPageState();
}

class _AmanPascaTriggerPageState extends State<AmanPascaTriggerPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  // Data dummy/hardcode
  final DateTime _waktuAman = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Durasi total animasi 900ms dengan stagger lambat
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _hitungPaddingH(double lebarLayar) {
    if (lebarLayar <= 480) return 24.0;
    return ((lebarLayar - 430) / 2).clamp(24.0, 120.0);
  }

  String _formatWaktu(DateTime dt) {
    final jam = dt.hour.toString().padLeft(2, '0');
    final menit = dt.minute.toString().padLeft(2, '0');
    return "$jam:$menit WIB";
  }

  @override
  Widget build(BuildContext context) {
    final lebarLayar = MediaQuery.of(context).size.width;
    final paddingH = _hitungPaddingH(lebarLayar);

    return PopScope(
      canPop: false, // Memblokir hardware back dan swipe back
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          automaticallyImplyLeading: false, // TIDAK ADA tombol back
          backgroundColor: Colors.white,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          centerTitle: true,
          title: Text(
            'Kamu Aman',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppConstants.textDark,
            ),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding:
                      EdgeInsets.symmetric(horizontal: paddingH, vertical: 32),
                  child: Column(
                    children: [
                      // Section 1: Hero Visual
                      _bangunHeroVisual(),

                      const SizedBox(height: 32),

                      // Section 2: Konfirmasi Status
                      _bangunKonfirmasiStatus(),

                      const SizedBox(height: 16),

                      // Section 3: Waktu Resolusi
                      _bangunWaktuResolusi(),

                      const SizedBox(height: 32),

                      // Section 4: Validasi Psikologis
                      _bangunValidasiPsikologis(),

                      const SizedBox(height: 32),

                      // Section 5: Aksi Lanjutan Opsional
                      _bangunAksiLanjutan(),
                    ],
                  ),
                ),
              ),
              // Tombol Utama (sticky bottom)
              _bangunTombolUtama(paddingH),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bangunHeroVisual() {
    // Icon hero scale elastic bounce (0ms -> end)
    final heroScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    // Teks Kamu Aman fade + slide up 10px (200ms -> end)
    // 200ms = 200/900 = 0.222
    final textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.222, 1.0, curve: Curves.easeOut),
      ),
    );

    final textSlide =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.222, 1.0, curve: Curves.easeOut),
      ),
    );

    return Column(
      children: [
        ScaleTransition(
          scale: heroScale,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppConstants.successColor.withValues(alpha: 0.1),
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              size: 52,
              color: AppConstants.successColor,
            ),
          ),
        ),
        const SizedBox(height: 24),
        FadeTransition(
          opacity: textFade,
          child: SlideTransition(
            position: textSlide,
            child: Column(
              children: [
                Text(
                  'Kamu Aman',
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppConstants.textDark,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Kontak daruratmu sudah diberi tahu',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppConstants.textSecondary,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _bangunKonfirmasiStatus() {
    // Fade in (380ms -> end)
    // 380/900 = 0.422
    final fade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.422, 1.0, curve: Curves.easeOut),
      ),
    );

    return FadeTransition(
      opacity: fade,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppConstants.successColor.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  size: 16,
                  color: AppConstants.successColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Pesan aman terkirim ke:',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.successColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: daftarKontakDarurat.map((kontak) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppConstants.successColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    kontak.nama,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppConstants.textDark,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bangunWaktuResolusi() {
    // Fade in (480ms -> end)
    // 480/900 = 0.533
    final fade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.533, 1.0, curve: Curves.easeOut),
      ),
    );

    return FadeTransition(
      opacity: fade,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.access_time_rounded,
            size: 14,
            color: AppConstants.textSecondary,
          ),
          const SizedBox(width: 6),
          Text(
            'Aman pada ${_formatWaktu(_waktuAman)}',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppConstants.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _bangunValidasiPsikologis() {
    // Fade + slide dari kiri (Offset -0.2, 0)
    // 580ms -> end
    // 580/900 = 0.644
    final fade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.644, 1.0, curve: Curves.easeOut),
      ),
    );

    final slide =
        Tween<Offset>(begin: const Offset(-0.2, 0), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.644, 1.0, curve: Curves.easeOut),
      ),
    );

    return FadeTransition(
      opacity: fade,
      child: SlideTransition(
        position: slide,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8F0),
            borderRadius: BorderRadius.circular(12),
            border: const Border(
              left: BorderSide(color: Color(0xFFF59E0B), width: 3),
            ),
          ),
          child: Text(
            'Reaksimu tadi adalah hal yang normal. Itu bukan kelemahanmu.',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppConstants.textDark,
              height: 1.6,
            ),
          ),
        ),
      ),
    );
  }

  Widget _bangunAksiLanjutan() {
    // Fade in bersamaan (700ms -> end)
    // 700/900 = 0.777
    final fade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.777, 1.0, curve: Curves.easeOut),
      ),
    );

    return FadeTransition(
      opacity: fade,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Langkah selanjutnya (opsional):',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppConstants.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Card Ceritakan Padaku
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    // Placeholder
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF5F5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.edit_note_rounded,
                          size: 24,
                          color: Color(0xFFCC0000),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Ceritakan\nPadaku',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppConstants.textDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tulis apa yang terjadi',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: AppConstants.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Card Buat Laporan
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    // Placeholder
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F4FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.description_rounded,
                          size: 24,
                          color: Color(0xFF2563EB),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Buat\nLaporan',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppConstants.textDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Catat secara resmi',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: AppConstants.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bangunTombolUtama(double paddingH) {
    // Fade in (800ms -> end)
    // 800/900 = 0.888
    final fade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.888, 1.0, curve: Curves.easeOut),
      ),
    );

    return FadeTransition(
      opacity: fade,
      child: Container(
        padding: EdgeInsets.fromLTRB(paddingH, 16, paddingH, 24),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade100)),
        ),
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  // Kembali ke awalan, bersihkan semua routenya sehingga tdk ada bekas state
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      AppConstants.primaryColor.withValues(alpha: 0.85),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Selesai',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Sesi ini tersimpan di Riwayat Pantauan',
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: AppConstants.textSecondary,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
