import 'package:flutter/material.dart';
import 'package:sigap_mobile/core/constants/app_constants.dart';
import 'package:sigap_mobile/core/widgets/blur_extension.dart';
import 'package:sigap_mobile/features/satgas_lite/presentation/widgets/satgas_widgets.dart';
import 'package:sigap_mobile/features/app_shell/presentation/pages/auth_check_screen.dart';

class AdminLitePage extends StatefulWidget {
  final String userName;

  const AdminLitePage({super.key, required this.userName});

  @override
  State<AdminLitePage> createState() => _AdminLitePageState();
}

class _AdminLitePageState extends State<AdminLitePage> {
  // Mock Data
  final List<Map<String, dynamic>> _mockAntrean = [
    {
      'id': 1,
      'kode': 'KAS-9921',
      'status': 'Darurat',
      'info': 'Mahasiswa melaporkan ancaman fisik dengan bukti foto.',
      'waktu': '2 mnt lalu',
      'darurat': 'darurat',
    },
    {
      'id': 2,
      'kode': 'KAS-9920',
      'status': 'Dispute',
      'info': 'Banding terhadap putusan sanksi tingkat 2.',
      'waktu': '1 jam lalu',
      'darurat': 'normal',
    },
    {
      'id': 3,
      'kode': 'KAS-9915',
      'status': 'Pending',
      'info': 'Laporan pelecehan verbal melalui chat, menunggu proses.',
      'waktu': '3 jam lalu',
      'darurat': 'normal',
    },
  ];

  String _filterActive = 'Terbaru';

  void _onTerimaKasus(int index) {
    setState(() {
      _mockAntrean.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white),
            SizedBox(width: 10),
            Text('Status kasus diperbarui: Diterima'),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _onTolakKasus(int index) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _BottomSheetAlasanTolak(
        onKirim: (alasan) {
          setState(() {
            _mockAntrean.removeAt(index);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.info_rounded, color: Colors.white),
                  SizedBox(width: 10),
                  Text('Kasus ditolak dan diarsipkan'),
                ],
              ),
              backgroundColor: Colors.red.shade600,
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
          // Latar Belakang "Glow Orb" Khas Aplikasi
          const _BackgroundLayerLite(color: AppConstants.urgentColor),
          
          Column(
            children: [
              _buildCleanHeader(),
              Expanded(
                child: _mockAntrean.isEmpty
                    ? _buildEmptyState()
                    : CustomScrollView(
                        physics: const BouncingScrollPhysics(),
                        slivers: [
                          _buildSummaryCardsSliver(),
                          _buildListHeaderSliver(),
                          SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final item = _mockAntrean[index];
                                return KasusSiagaCard(
                                  item: item,
                                  swipeRightLabel: 'Terima & Proses',
                                  swipeRightIcon: Icons.assignment_turned_in_rounded,
                                  swipeRightColor: Colors.green.shade600,
                                  swipeLeftLabel: 'Tolak',
                                  swipeLeftIcon: Icons.cancel_rounded,
                                  swipeLeftColor: Colors.red.shade600,
                                  onSwipeRight: () => _onTerimaKasus(index),
                                  onSwipeLeft: () => _onTolakKasus(index),
                                );
                              },
                              childCount: _mockAntrean.length,
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
                  'Mode Admin',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.urgentColor.withValues(alpha: 0.8),
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  widget.userName,
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
            _buildStatCard('Darurat', '1', Icons.warning_rounded, Colors.red),
            const SizedBox(width: 16),
            _buildStatCard('Diproses', '3', Icons.folder_rounded, AppConstants.primaryColor),
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
              'Antrean Laporan',
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
                const PopupMenuItem(value: 'Terbaru', child: Text('Terbaru')),
                const PopupMenuItem(value: 'Darurat', child: Text('Mendesak (Darurat)')),
                const PopupMenuItem(value: 'Dispute', child: Text('Status Dispute')),
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
                    Icon(Icons.keyboard_arrow_down_rounded,
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
          Icon(Icons.inbox_outlined, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            'Antrean Kosong',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppConstants.textDark),
          ),
          const SizedBox(height: 8),
          Text(
            'Tidak ada kasus yang\nmenunggu tindakan.',
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
          top: -50,
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


/// Bottom Sheet untuk input alasan penolakan
class _BottomSheetAlasanTolak extends StatefulWidget {
  final Function(String) onKirim;

  const _BottomSheetAlasanTolak({required this.onKirim});

  @override
  State<_BottomSheetAlasanTolak> createState() =>
      _BottomSheetAlasanTolakState();
}

class _BottomSheetAlasanTolakState extends State<_BottomSheetAlasanTolak> {
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
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.warning_rounded, color: Colors.red.shade600),
              ),
              const SizedBox(width: 12),
              const Text(
                'Tolak Kasus',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Alasan penolakan (wajib diisi):',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _ctrl,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Misal: Bukti tidak relevan, salah kategori...',
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
                borderSide: BorderSide(color: AppConstants.urgentColor),
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.urgentColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              onPressed: () {
                if (_ctrl.text.trim().isEmpty) return;
                Navigator.pop(context);
                widget.onKirim(_ctrl.text);
              },
              child: const Text('Kirim & Arsipkan',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
