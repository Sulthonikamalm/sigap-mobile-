import 'package:flutter/material.dart';
import 'package:sigap_mobile/core/constants/app_constants.dart';
import '../../data/models/report_monitor_record.dart';
import '../../data/mock/mock_report_data.dart';
import '../widgets/timeline_tracker.dart';
import '../widgets/audit_trail_list.dart';

/// State sealed class — representasi semua kemungkinan state halaman monitor.
sealed class MonitorViewState {
  const MonitorViewState();
}

class MonitorEmpty extends MonitorViewState {
  const MonitorEmpty();
}

class MonitorLoading extends MonitorViewState {
  const MonitorLoading();
}

class MonitorError extends MonitorViewState {
  final String message;
  const MonitorError(this.message);
}

class MonitorSuccess extends MonitorViewState {
  final ReportMonitorRecord record;
  const MonitorSuccess(this.record);
}

/// Single source of truth untuk seluruh state & logika halaman Report Monitor.
///
/// Menggantikan _state, _activeRecord, _searchRequestId, _errorMessage,
/// dan semua method bisnis yang sebelumnya hidup di _ReportMonitorPageState.
class ReportMonitorNotifier extends ChangeNotifier {
  MonitorViewState _state = const MonitorEmpty();
  MonitorViewState get state => _state;

  ReportMonitorRecord? _activeRecord;
  ReportMonitorRecord? get activeRecord => _activeRecord;

  int _searchRequestId = 0;

  bool _isDownloading = false;
  bool get isDownloading => _isDownloading;

  /// Apakah text di search bar berbeda dari record yang sedang ditampilkan?
  bool hasDraftSearch(String currentText) {
    final activeCode = _activeRecord?.reportCode;
    if (activeCode == null) return false;
    return _normalizeQuery(currentText) != activeCode;
  }

  /// Cari laporan berdasarkan kode ID.
  Future<void> performSearch(String query) async {
    final normalized = _normalizeQuery(query);

    if (normalized.isEmpty) {
      _state = const MonitorError(
          'Silakan masukkan ID laporan terlebih dahulu.');
      notifyListeners();
      return;
    }

    final requestId = ++_searchRequestId;

    _state = const MonitorLoading();
    notifyListeners();

    // Simulasi network delay — di production: await api.getReport(normalized)
    await Future<void>.delayed(const Duration(milliseconds: 900));

    // Guard: jika ada request lebih baru, abaikan hasil ini
    if (requestId != _searchRequestId) return;

    final record = MockReportData.lookup(normalized);
    if (record == null) {
      _state = MonitorError(
          'Laporan dengan ID "$normalized" tidak ditemukan. Periksa kembali kode yang Anda masukkan.');
      notifyListeners();
      return;
    }

    _activeRecord = record;
    _state = MonitorSuccess(record);
    notifyListeners();
  }

  /// Logika saat user mengubah text di search bar.
  void onSearchInputChanged(String value) {
    if (_state is MonitorError) {
      if (value.trim().isEmpty) {
        _state = const MonitorEmpty();
      }
      notifyListeners();
      return;
    }

    // Jika sudah ada active record dan user mulai ubah text, notify
    // agar UI bisa menampilkan banner "draft search"
    if (_activeRecord != null) {
      notifyListeners();
    }
  }

  /// Pelapor menyetujui tindak lanjut.
  Future<void> acceptRecommendation() async {
    final currentRecord = _activeRecord;
    if (currentRecord == null ||
        currentRecord.feedbackState != FeedbackActionState.waiting) {
      return;
    }

    try {
      // Simulasi API call
      await Future<void>.delayed(const Duration(milliseconds: 500));

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
      _state = MonitorSuccess(_activeRecord!);
      notifyListeners();
    } catch (e) {
      rethrow; // Biarkan UI menampilkan SnackBar error
    }
  }

  /// Pelapor meminta penjadwalan ulang.
  Future<void> requestReschedule() async {
    final currentRecord = _activeRecord;
    if (currentRecord == null ||
        currentRecord.feedbackState != FeedbackActionState.waiting) {
      return;
    }

    try {
      // Simulasi API call
      await Future<void>.delayed(const Duration(milliseconds: 500));

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
      _state = MonitorSuccess(_activeRecord!);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  /// Download PDF dari backend.
  Future<void> downloadPdf() async {
    if (_isDownloading) return;
    _isDownloading = true;
    notifyListeners();

    try {
      // Simulasi API call — di production:
      // final url = await api.getExportPdfUrl(activeRecord!.reportCode);
      // await launchUrl(Uri.parse(url));
      await Future<void>.delayed(const Duration(seconds: 2));
    } finally {
      _isDownloading = false;
      notifyListeners();
    }
  }

  // ──────────────────────────────────────────────
  //  Helpers
  // ──────────────────────────────────────────────

  List<TimelineStepModel> _markTimelineConfirmed(
      List<TimelineStepModel> steps) {
    if (steps.isEmpty) return steps;

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

  String _normalizeQuery(String value) => value.trim().toUpperCase();

  String _buildNowLabel() {
    final now = DateTime.now();
    final day = now.day.toString().padLeft(2, '0');
    final month = now.month.toString().padLeft(2, '0');
    final year = now.year.toString();
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    return '$day/$month/$year, $hour:$minute';
  }
}
