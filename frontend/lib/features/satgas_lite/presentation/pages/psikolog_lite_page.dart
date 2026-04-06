import 'package:flutter/material.dart';
import 'package:sigap_mobile/core/constants/app_constants.dart';
import 'package:sigap_mobile/core/widgets/blur_extension.dart';
import 'package:sigap_mobile/features/satgas_lite/presentation/widgets/satgas_widgets.dart';
import 'package:sigap_mobile/features/app_shell/presentation/pages/auth_check_screen.dart';

class PsikologLitePage extends StatefulWidget {
  final String userName;

  const PsikologLitePage({super.key, required this.userName});

  @override
  State<PsikologLitePage> createState() => _PsikologLitePageState();
}

class _PsikologLitePageState extends State<PsikologLitePage> {
  // Mock Data
  final List<Map<String, dynamic>> _mockJadwal = [
    {
      'id': 101,
      'kode': 'KSL-8841',
      'status': 'Terjadwal',
      'info': 'Konseling kecemasan akademik (Virtual)',
      'waktu': 'Hari ini, 14:00',
      'darurat': 'normal',
    },
    {
      'id': 102,
      'kode': 'KSL-8842',
      'status': 'Dispute',
      'info': 'Rekomendasi cuti akademik ditolak prodi.',
      'waktu': 'Besok, 09:00',
      'darurat': 'darurat',
    },
  ];

  String _filterActive = 'Mendesak';

  void _onMulaiSesi(int index) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.videocam_rounded, color: Colors.white),
            SizedBox(width: 10),
            Text('Link meeting dikirim ke mahasiswa'),
          ],
        ),
        backgroundColor: Colors.blue.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _onBeriCatatan(int index) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _BottomSheetCatatanPsikolog(
        onSimpan: (catatan) {
          setState(() {
            _mockJadwal.removeAt(index);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: Colors.white),
                  SizedBox(width: 10),
                  Text('Sesi ditutup & catatan tersimpan'),
                ],
              ),
              backgroundColor: Colors.teal.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: Stack(
        children: [
          // Latar Belakang "Glow Orb"
          const _BackgroundLayerLite(color: Colors.teal),

          Column(
            children: [
              _buildCleanHeader(),
              Expanded(
                child: _mockJadwal.isEmpty
                    ? _buildEmptyState()
                    : CustomScrollView(
                        physics: const BouncingScrollPhysics(),
                        slivers: [
                          _buildSummaryCardsSliver(),
                          _buildListHeaderSliver(),
                          SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final item = _mockJadwal[index];
                                return KasusSiagaCard(
                                  item: item,
                                  swipeRightLabel: 'Mulai Sesi',
                                  swipeRightIcon: Icons.play_arrow_rounded,
                                  swipeRightColor: Colors.blue.shade600,
                                  swipeLeftLabel: 'Selesai & Catat',
                                  swipeLeftIcon: Icons.edit_note_rounded,
                                  swipeLeftColor: Colors.teal.shade600,
                                  onSwipeRight: () => _onMulaiSesi(index),
                                  onSwipeLeft: () => _onBeriCatatan(index),
                                );
                              },
                              childCount: _mockJadwal.length,
                            ),
                          ),
                          const SliverToBoxAdapter(child: SizedBox(height: 30)),
                        ],
                      ),
              ),
              const RambuDisiplinFooter(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCleanHeader() {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Klinik Satgas',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.teal.shade600,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  'Psikolog ${widget.userName}',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppConstants.textDark,
                  ),
                ),
              ],
            ),
            InkWell(
              onTap: () {
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AuthCheckScreen()));
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.logout_rounded,
                    color: AppConstants.textDark, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCardsSliver() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        child: Row(
          children: [
            _buildStatCard('Hari Ini', '2', Icons.calendar_today_rounded, Colors.blue),
            const SizedBox(width: 16),
            _buildStatCard('Menunggu', '1', Icons.hourglass_top_rounded, Colors.orange),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String count, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 16),
            Text(
              count,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: AppConstants.textDark,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListHeaderSliver() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Agenda Konsultasi',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppConstants.textDark,
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (val) {
                setState(() => _filterActive = val);
              },
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'Mendesak', child: Text('Mendesak')),
                const PopupMenuItem(value: 'Hari Ini', child: Text('Hari Ini')),
                const PopupMenuItem(value: 'Minggu Ini', child: Text('Minggu Ini')),
              ],
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Text(
                      _filterActive,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.filter_list_rounded,
                        size: 16, color: Colors.grey.shade600),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_available_outlined, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            'Hari Ini Kosong',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppConstants.textDark),
          ),
          const SizedBox(height: 8),
          Text(
            'Tidak ada jadwal konsultasi\nyang perlu ditangani.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}

// ----- BACKGROUND LAYER LITE (Gaya Original Vibe) -----
class _BackgroundLayerLite extends StatelessWidget {
  final Color color;
  const _BackgroundLayerLite({required this.color});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -30,
          right: -20,
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.15),
            ),
          ).blurred(blur: 80),
        ),
        Positioned(
          top: 150,
          left: -40,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppConstants.primaryColor.withValues(alpha: 0.1),
            ),
          ).blurred(blur: 80),
        ),
      ],
    );
  }
}

/// Bottom Sheet untuk input catatan P3K Psikologi
class _BottomSheetCatatanPsikolog extends StatefulWidget {
  final Function(String) onSimpan;

  const _BottomSheetCatatanPsikolog({required this.onSimpan});

  @override
  State<_BottomSheetCatatanPsikolog> createState() =>
      _BottomSheetCatatanPsikologState();
}

class _BottomSheetCatatanPsikologState
    extends State<_BottomSheetCatatanPsikolog> {
  final TextEditingController _ctrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 24,
        right: 24,
        top: 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  shape: BoxShape.circle,
                ),
                child:
                    Icon(Icons.medical_services_rounded, color: Colors.teal.shade600),
              ),
              const SizedBox(width: 12),
              const Text(
                'Catatan Rekam Sesi',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Kesimpulan awal (P3K Psikologis):',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _ctrl,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Tuliskan observasi singkat, mood, atau saran...',
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.teal.shade600),
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              onPressed: () {
                if (_ctrl.text.trim().isEmpty) return;
                Navigator.pop(context);
                widget.onSimpan(_ctrl.text);
              },
              child: const Text('Simpan & Tutup Sesi',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
