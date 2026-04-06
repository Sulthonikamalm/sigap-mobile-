import 'package:flutter/material.dart';
import '../../presentation/widgets/timeline_tracker.dart';
import '../../presentation/widgets/audit_trail_list.dart';
import 'package:sigap_mobile/core/constants/app_constants.dart';
import '../models/report_monitor_record.dart';

class MockReportData {
  static ReportMonitorRecord? lookup(String query) {
    final mockRecords = <String, ReportMonitorRecord>{
      'SIGAP-24001': const ReportMonitorRecord(
        reportCode: 'SIGAP-24001',
        title: 'Laporan Kekerasan Verbal (Anonim)',
        createdAtLabel: 'Dilaporkan pada 12 Nov 2026',
        statusLabel: 'TINDAK LANJUT',
        statusIcon: Icons.pending_rounded,
        statusColor: Colors.orange,
        timelineSteps: [
          TimelineStepModel(
            title: 'Laporan Diterima',
            description: 'Laporan berhasil masuk ke sistem SIGAP.',
            date: '12 Nov',
            status: TimelineStatus.success,
          ),
          TimelineStepModel(
            title: 'Verifikasi Satgas',
            description:
                'Satgas melakukan verifikasi awal terhadap laporan dan bukti pendukung.',
            date: '13 Nov',
            status: TimelineStatus.success,
          ),
          TimelineStepModel(
            title: 'Tindak Lanjut',
            description:
                'Tim menyiapkan sesi tindak lanjut dan pendampingan awal.',
            date: '15 Nov',
            status: TimelineStatus.pending,
          ),
          TimelineStepModel(
            title: 'Konfirmasi Pelapor',
            description:
                'Sistem menunggu persetujuan pelapor atas jadwal lanjutan yang diajukan.',
            date: '-',
            status: TimelineStatus.loading,
          ),
        ],
        schedule: ScheduleCardData(
          title: 'Senin, 18 Nov 2026',
          subtitle: 'Pukul 10:00 - 11:30 WIB (Ruang Konseling B)',
        ),
        consultationNote:
            'Setelah verifikasi awal, pelapor disarankan mengikuti sesi konseling tahap 1 untuk asesmen kondisi psikologis. Mohon hadir tepat waktu.',
        feedbackPrompt:
            'Apakah jadwal dan tindakan yang disarankan dapat Anda terima?',
        feedbackState: FeedbackActionState.waiting,
        auditTrail: [
          AuditTrailItem(
            date: '15 Nov 2026, 09:12 WIB',
            description: 'Status berubah ke Tindak Lanjut',
            details:
                'Oleh Satgas Penanganan (perubahan status dari tahap verifikasi ke tindak lanjut).',
          ),
          AuditTrailItem(
            date: '13 Nov 2026, 14:30 WIB',
            description: 'Laporan Selesai Diverifikasi',
            details: 'Oleh Admin Utama (verifikasi tahap 1 divalidasi).',
          ),
          AuditTrailItem(
            date: '12 Nov 2026, 10:05 WIB',
            description: 'Laporan Masuk',
            details: 'Pelapor anonim mengirimkan laporan kekerasan verbal.',
          ),
        ],
      ),
      'SIGAP-24002': const ReportMonitorRecord(
        reportCode: 'SIGAP-24002',
        title: 'Laporan Pelecehan Daring',
        createdAtLabel: 'Dilaporkan pada 03 Des 2026',
        statusLabel: 'SELESAI',
        statusIcon: Icons.check_circle_rounded,
        statusColor: AppConstants.successColor,
        timelineSteps: [
          TimelineStepModel(
            title: 'Laporan Diterima',
            description: 'Laporan berhasil dicatat dan diamankan oleh sistem.',
            date: '03 Des',
            status: TimelineStatus.success,
          ),
          TimelineStepModel(
            title: 'Verifikasi Bukti',
            description:
                'Tim memverifikasi bukti percakapan dan identitas pihak terkait.',
            date: '04 Des',
            status: TimelineStatus.success,
          ),
          TimelineStepModel(
            title: 'Pendampingan Selesai',
            description:
                'Sesi pendampingan dan klarifikasi telah dilakukan sesuai jadwal.',
            date: '06 Des',
            status: TimelineStatus.success,
          ),
          TimelineStepModel(
            title: 'Kasus Ditutup',
            description:
                'Pelapor telah mengonfirmasi hasil penanganan dan kasus ditutup.',
            date: '08 Des',
            status: TimelineStatus.success,
          ),
        ],
        schedule: null,
        consultationNote:
            'Pendampingan telah selesai. Pelapor menyetujui rekomendasi penanganan lanjutan dan tidak ada aksi tambahan yang tertunda.',
        feedbackPrompt:
            'Pelapor telah menyelesaikan proses konfirmasi dan tindak lanjut.',
        feedbackState: FeedbackActionState.accepted,
        auditTrail: [
          AuditTrailItem(
            date: '08 Des 2026, 16:40 WIB',
            description: 'Kasus Ditutup',
            details: 'Penanganan dinyatakan selesai dan disetujui pelapor.',
          ),
          AuditTrailItem(
            date: '06 Des 2026, 11:10 WIB',
            description: 'Pendampingan Dilaksanakan',
            details: 'Sesi pendampingan selesai sesuai jadwal.',
          ),
          AuditTrailItem(
            date: '04 Des 2026, 08:45 WIB',
            description: 'Bukti Terverifikasi',
            details: 'Tim memvalidasi bukti pendukung yang dikirim pelapor.',
          ),
        ],
      ),
    };

    return mockRecords[query];
  }
}
