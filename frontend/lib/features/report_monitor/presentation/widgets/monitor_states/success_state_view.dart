import 'package:flutter/material.dart';
import 'package:sigap_mobile/core/constants/app_constants.dart';
import '../../../data/models/report_monitor_record.dart';
import '../timeline_tracker.dart';
import '../status_phase_card.dart';
import '../audit_trail_list.dart';

class SuccessMonitorView extends StatelessWidget {
  final ReportMonitorRecord record;
  final VoidCallback onRescheduleRequest;
  final VoidCallback onAcceptRecommendation;
  final VoidCallback onDownloadPdf;

  const SuccessMonitorView({
    super.key,
    required this.record,
    required this.onRescheduleRequest,
    required this.onAcceptRecommendation,
    required this.onDownloadPdf,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildResultHeader(record),
        const SizedBox(height: 16),
        _buildDownloadPdfButton(),
        const SizedBox(height: 16),
        Text(
          'Timeline Penanganan',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 20),
        TimelineTracker(steps: record.timelineSteps),
        const SizedBox(height: 16),
        if (record.schedule != null)
          StatusPhaseCard(
            title: 'Jadwal Konsultasi',
            icon: Icons.calendar_month_rounded,
            iconColor: Colors.deepPurple,
            content: _buildScheduleContent(record.schedule!),
          ),
        StatusPhaseCard(
          title: 'Catatan Psikolog',
          icon: Icons.notes_rounded,
          iconColor: Colors.teal,
          content: Text(
            record.consultationNote,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              height: 1.5,
            ),
          ),
        ),
        StatusPhaseCard(
          title: 'Konfirmasi Pelapor',
          icon: Icons.feedback_rounded,
          iconColor: Colors.orange,
          content: _buildFeedbackContent(record),
        ),
        const SizedBox(height: 8),
        AuditTrailList(items: record.auditTrail),
      ],
    );
  }

  Widget _buildDownloadPdfButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onDownloadPdf,
        icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.redAccent),
        label: const Text(
          'Unduh Tiket & Laporan (PDF)',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          foregroundColor: AppConstants.textDark,
          side: BorderSide(color: Colors.grey.shade300),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildResultHeader(ReportMonitorRecord record) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppConstants.primaryColor, Color(0xFF5D8BBF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppConstants.primaryColor.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  record.reportCode,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: record.statusColor.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(record.statusIcon, color: Colors.white, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      record.statusLabel,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            record.title,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            record.createdAtLabel,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleContent(ScheduleCardData schedule) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.deepPurple.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.event_available_rounded,
            color: Colors.deepPurple,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                schedule.title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                schedule.subtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeedbackContent(ReportMonitorRecord record) {
    switch (record.feedbackState) {
      case FeedbackActionState.accepted:
        return _buildFeedbackResolvedState(
          title: 'Konfirmasi sudah diterima',
          description:
              'Tidak ada tindakan tambahan dari pelapor. Tim dapat melanjutkan proses sesuai jadwal.',
          color: AppConstants.successColor,
          icon: Icons.verified_rounded,
        );
      case FeedbackActionState.rescheduleRequested:
        return _buildFeedbackResolvedState(
          title: 'Permintaan reschedule sedang ditinjau',
          description:
              'Tim penanganan akan menghubungi Anda kembali setelah jadwal alternatif disiapkan.',
          color: Colors.orange,
          icon: Icons.update_rounded,
        );
      case FeedbackActionState.waiting:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              record.feedbackPrompt,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onRescheduleRequest,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Ajukan Reschedule',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onAcceptRecommendation,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: AppConstants.primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Ya, Saya Setuju'),
                  ),
                ),
              ],
            ),
          ],
        );
    }
  }

  Widget _buildFeedbackResolvedState({
    required String title,
    required String description,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    height: 1.5,
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
