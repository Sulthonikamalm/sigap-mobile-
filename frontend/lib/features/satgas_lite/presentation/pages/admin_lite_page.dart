import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sigap_mobile/core/constants/app_constants.dart';
import 'package:sigap_mobile/features/satgas_lite/domain/entities/kasus_item.dart';
import 'package:sigap_mobile/features/satgas_lite/data/repositories/mock_kasus_repository.dart';
import 'package:sigap_mobile/features/satgas_lite/presentation/notifiers/satgas_notifier.dart';
import 'package:sigap_mobile/features/satgas_lite/presentation/widgets/satgas_widgets.dart';
import 'package:sigap_mobile/features/satgas_lite/presentation/widgets/shared_satgas_widgets.dart';
import 'package:sigap_mobile/features/app_shell/presentation/pages/auth_check_screen.dart';

class AdminLitePage extends StatelessWidget {
  final String userName;

  const AdminLitePage({super.key, required this.userName});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<SatgasNotifier>(
      create: (_) {
        final notifier = SatgasNotifier(
          repository: MockKasusRepository(role: SatgasRole.admin),
        );
        notifier.loadKasus();
        return notifier;
      },
      child: _AdminLiteView(userName: userName),
    );
  }
}

/// View murni — hanya membaca state dari [SatgasNotifier].
class _AdminLiteView extends StatelessWidget {
  final String userName;

  const _AdminLiteView({required this.userName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: Stack(
        children: [
          const SatgasBackgroundLayer(color: AppConstants.urgentColor),
          Column(
            children: [
              _AdminHeader(userName: userName),
              Expanded(
                child: Consumer<SatgasNotifier>(
                  builder: (context, notifier, _) {
                    return switch (notifier.state) {
                      KasusInitial() || KasusLoading() =>
                        const Center(
                          child: CircularProgressIndicator(
                            color: AppConstants.primaryColor,
                          ),
                        ),
                      KasusError(message: final msg) =>
                        Center(child: Text(msg)),
                      KasusLoaded(items: final items) =>
                        items.isEmpty
                            ? const SatgasEmptyState(
                                title: 'Antrean Kosong',
                                subtitle: 'Tidak ada kasus yang\nmenunggu tindakan.',
                                icon: Icons.inbox_outlined,
                              )
                            : _AdminKasusList(items: items),
                    };
                  },
                ),
              ),
              const RambuDisiplinFooter(),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
//  ADMIN HEADER
// ─────────────────────────────────────────────────────

class _AdminHeader extends StatelessWidget {
  final String userName;

  const _AdminHeader({required this.userName});

  @override
  Widget build(BuildContext context) {
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
                  userName,
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
                  MaterialPageRoute(builder: (_) => const AuthCheckScreen()),
                );
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
}

// ─────────────────────────────────────────────────────
//  KASUS LIST
// ─────────────────────────────────────────────────────

class _AdminKasusList extends StatelessWidget {
  final List<KasusItem> items;

  const _AdminKasusList({required this.items});

  @override
  Widget build(BuildContext context) {
    final notifier = context.read<SatgasNotifier>();

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Row(
              children: [
                SatgasStatCard(
                  title: 'Darurat',
                  count: notifier.jumlahDarurat.toString(),
                  icon: Icons.warning_rounded,
                  color: Colors.red,
                ),
                const SizedBox(width: 16),
                SatgasStatCard(
                  title: 'Diproses',
                  count: notifier.totalAntrean.toString(),
                  icon: Icons.folder_rounded,
                  color: AppConstants.primaryColor,
                ),
              ],
            ),
          ),
        ),
        const SatgasListHeader(
          title: 'Antrean Laporan',
          filterOptions: [
            KasusFilter.terbaru,
            KasusFilter.mendesak,
            KasusFilter.dispute,
          ],
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final item = items[index];
              return KasusSiagaCard(
                item: item.toMap(),
                swipeRightLabel: 'Terima & Proses',
                swipeRightIcon: Icons.assignment_turned_in_rounded,
                swipeRightColor: Colors.green.shade600,
                swipeLeftLabel: 'Tolak',
                swipeLeftIcon: Icons.cancel_rounded,
                swipeLeftColor: Colors.red.shade600,
                onSwipeRight: () => _onTerimaKasus(context, item),
                onSwipeLeft: () => _onTolakKasus(context, item),
              );
            },
            childCount: items.length,
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 30)),
      ],
    );
  }

  Future<void> _onTerimaKasus(BuildContext context, KasusItem item) async {
    final notifier = context.read<SatgasNotifier>();
    final result = await notifier.terimaKasus(item.id);

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              result.success
                  ? Icons.check_circle_rounded
                  : Icons.error_rounded,
              color: Colors.white,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(result.message)),
          ],
        ),
        backgroundColor:
            result.success ? Colors.green.shade600 : Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _onTolakKasus(BuildContext context, KasusItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _BottomSheetAlasanTolak(
        onKirim: (alasan) async {
          final notifier = context.read<SatgasNotifier>();
          final result = await notifier.tolakKasus(item.id, alasan);

          if (!context.mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(
                    result.success
                        ? Icons.info_rounded
                        : Icons.error_rounded,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(result.message)),
                ],
              ),
              backgroundColor: result.success
                  ? Colors.red.shade600
                  : Colors.orange.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
//  BOTTOM SHEET ALASAN TOLAK
// ─────────────────────────────────────────────────────

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
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

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
                borderSide: const BorderSide(color: AppConstants.urgentColor),
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
