import 'package:flutter/material.dart';
import 'package:sigap_mobile/core/constants/app_constants.dart';
import 'package:sigap_mobile/features/report_monitor/presentation/widgets/audit_trail_list.dart';
import 'package:sigap_mobile/features/report_monitor/presentation/widgets/timeline_tracker.dart';
import 'package:sigap_mobile/features/report_monitor/data/models/report_monitor_record.dart';
import 'package:sigap_mobile/features/report_monitor/data/mock/mock_report_data.dart';
import 'package:sigap_mobile/features/report_monitor/presentation/widgets/monitor_states/monitor_status_views.dart';
import 'package:sigap_mobile/features/report_monitor/presentation/widgets/monitor_states/success_state_view.dart';
import 'package:sigap_mobile/features/report_monitor/presentation/widgets/monitor_states/search_panel_view.dart';

enum MonitorState { empty, loading, error, success }

class ReportMonitorPage extends StatefulWidget {
  const ReportMonitorPage({super.key});

  @override
  State<ReportMonitorPage> createState() => _ReportMonitorPageState();
}

class _ReportMonitorPageState extends State<ReportMonitorPage> {
  final TextEditingController _searchController = TextEditingController();

  MonitorState _state = MonitorState.empty;
  String _errorMessage = '';
  ReportMonitorRecord? _activeRecord;
  int _searchRequestId = 0;

  bool get _isLoading => _state == MonitorState.loading;

  bool get _hasDraftSearch {
    final activeCode = _activeRecord?.reportCode;
    if (activeCode == null) {
      return false;
    }

    return _normalizeQuery(_searchController.text) != activeCode;
  }

  Future<void> _performSearch() async {
    FocusScope.of(context).unfocus();
    final query = _normalizeQuery(_searchController.text);

    if (query.isEmpty) {
      setState(() {
        _state = MonitorState.error;
        _errorMessage = 'Silakan masukkan ID laporan terlebih dahulu.';
      });
      return;
    }

    final requestId = ++_searchRequestId;

    setState(() {
      _state = MonitorState.loading;
      _errorMessage = '';
    });

    await Future<void>.delayed(const Duration(milliseconds: 900));

    if (!mounted || requestId != _searchRequestId) {
      return;
    }

    final record = MockReportData.lookup(query);
    if (record == null) {
      setState(() {
        _state = MonitorState.error;
        _errorMessage =
            'Laporan dengan ID "$query" tidak ditemukan. Periksa kembali kode yang Anda masukkan.';
      });
      return;
    }

    setState(() {
      _activeRecord = record;
      _state = MonitorState.success;
    });
  }

  void _handleSearchInputChanged(String value) {
    if (_state == MonitorState.error) {
      setState(() {
        _state = value.trim().isEmpty ? MonitorState.empty : MonitorState.error;
        if (_state == MonitorState.empty) {
          _errorMessage = '';
        }
      });
      return;
    }

    if (_activeRecord != null) {
      setState(() {});
    }
  }

  void _handleAcceptRecommendation() {
    final currentRecord = _activeRecord;
    if (currentRecord == null ||
        currentRecord.feedbackState != FeedbackActionState.waiting) {
      return;
    }

    setState(() {
      _activeRecord = currentRecord.copyWith(
        statusLabel: 'TERKONFIRMASI',
        statusIcon: Icons.verified_rounded,
        statusColor: AppConstants.successColor,
        timelineSteps: _markTimelineConfirmed(currentRecord.timelineSteps),
        feedbackState: FeedbackActionState.accepted,
        consultationNote:
            '${currentRecord.consultationNote}\n\nKonfirmasi pelapor telah diterima oleh sistem.',
        auditTrail: [
          AuditTrailItem(
            date: _buildNowLabel(),
            description: 'Pelapor Menyetujui Tindak Lanjut',
            details:
                'Konfirmasi diterima melalui aplikasi mobile. Jadwal konseling dinyatakan sesuai.',
          ),
          ...currentRecord.auditTrail,
        ],
      );
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Konfirmasi Anda sudah diterima.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleRescheduleRequest() {
    final currentRecord = _activeRecord;
    if (currentRecord == null ||
        currentRecord.feedbackState != FeedbackActionState.waiting) {
      return;
    }

    setState(() {
      _activeRecord = currentRecord.copyWith(
        statusLabel: 'RESCHEDULE',
        statusIcon: Icons.update_rounded,
        statusColor: Colors.orange,
        feedbackState: FeedbackActionState.rescheduleRequested,
        consultationNote:
            '${currentRecord.consultationNote}\n\nPelapor meminta penjadwalan ulang. Tim akan meninjau ulang jadwal.',
        auditTrail: [
          AuditTrailItem(
            date: _buildNowLabel(),
            description: 'Permintaan Reschedule Diajukan',
            details:
                'Pelapor meminta peninjauan jadwal lanjutan melalui aplikasi mobile.',
          ),
          ...currentRecord.auditTrail,
        ],
      );
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Permintaan reschedule berhasil dicatat.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  List<TimelineStepModel> _markTimelineConfirmed(
    List<TimelineStepModel> steps,
  ) {
    if (steps.isEmpty) {
      return steps;
    }

    return [
      ...steps.take(steps.length - 1),
      const TimelineStepModel(
        title: 'Konfirmasi Pelapor',
        description:
            'Pelapor telah menyetujui tindak lanjut dan jadwal yang disarankan.',
        date: 'Hari ini',
        status: TimelineStatus.success,
      ),
    ];
  }



  String _normalizeQuery(String value) {
    return value.trim().toUpperCase();
  }

  String _buildNowLabel() {
    final now = DateTime.now();
    final day = now.day.toString().padLeft(2, '0');
    final month = now.month.toString().padLeft(2, '0');
    final year = now.year.toString();
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    return '$day/$month/$year, $hour:$minute';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          const SizedBox(height: 24),
                          _buildSearchPanel(),
                          if (_state == MonitorState.error) ...[
                            const SizedBox(height: 20),
                            _buildErrorBanner(),
                          ],
                          if (_hasDraftSearch) ...[
                            const SizedBox(height: 16),
                            _buildDraftInfoBanner(),
                          ],
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildContentArea(),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 40)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchPanel() {
    return SearchPanelView(
      controller: _searchController,
      isLoading: _isLoading,
      onChanged: _handleSearchInputChanged,
      onSearch: _performSearch,
    );
  }

  Widget _buildErrorBanner() {
    return ErrorBannerView(errorMessage: _errorMessage);
  }

  Widget _buildDraftInfoBanner() {
    return DraftInfoBannerView(
      currentCode: _activeRecord?.reportCode ?? '',
    );
  }

  Widget _buildContentArea() {
    switch (_state) {
      case MonitorState.empty:
        return const EmptyMonitorView();
      case MonitorState.loading:
        return const LoadingMonitorView();
      case MonitorState.error:
        return const NotFoundMonitorView();
      case MonitorState.success:
        final record = _activeRecord;
        if (record == null) {
          return const NotFoundMonitorView();
        }
        return SuccessMonitorView(
          record: record,
          onRescheduleRequest: _handleRescheduleRequest,
          onAcceptRecommendation: _handleAcceptRecommendation,
        );
    }
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 12, 20, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade100),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.arrow_back_rounded,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PANTAU',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'Pantau Progres Laporan Anda',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
