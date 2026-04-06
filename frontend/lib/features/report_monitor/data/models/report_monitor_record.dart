import 'package:flutter/material.dart';
import '../../presentation/widgets/timeline_tracker.dart';
import '../../presentation/widgets/audit_trail_list.dart';

enum FeedbackActionState { waiting, accepted, rescheduleRequested }

class ScheduleCardData {
  final String title;
  final String subtitle;

  const ScheduleCardData({
    required this.title,
    required this.subtitle,
  });
}

class ReportMonitorRecord {
  final String reportCode;
  final String title;
  final String createdAtLabel;
  final String statusLabel;
  final IconData statusIcon;
  final Color statusColor;
  final List<TimelineStepModel> timelineSteps;
  final ScheduleCardData? schedule;
  final String consultationNote;
  final String feedbackPrompt;
  final FeedbackActionState feedbackState;
  final List<AuditTrailItem> auditTrail;

  const ReportMonitorRecord({
    required this.reportCode,
    required this.title,
    required this.createdAtLabel,
    required this.statusLabel,
    required this.statusIcon,
    required this.statusColor,
    required this.timelineSteps,
    required this.schedule,
    required this.consultationNote,
    required this.feedbackPrompt,
    required this.feedbackState,
    required this.auditTrail,
  });

  ReportMonitorRecord copyWith({
    String? reportCode,
    String? title,
    String? createdAtLabel,
    String? statusLabel,
    IconData? statusIcon,
    Color? statusColor,
    List<TimelineStepModel>? timelineSteps,
    ScheduleCardData? schedule,
    bool clearSchedule = false,
    String? consultationNote,
    String? feedbackPrompt,
    FeedbackActionState? feedbackState,
    List<AuditTrailItem>? auditTrail,
  }) {
    return ReportMonitorRecord(
      reportCode: reportCode ?? this.reportCode,
      title: title ?? this.title,
      createdAtLabel: createdAtLabel ?? this.createdAtLabel,
      statusLabel: statusLabel ?? this.statusLabel,
      statusIcon: statusIcon ?? this.statusIcon,
      statusColor: statusColor ?? this.statusColor,
      timelineSteps: timelineSteps ?? this.timelineSteps,
      schedule: clearSchedule ? null : schedule ?? this.schedule,
      consultationNote: consultationNote ?? this.consultationNote,
      feedbackPrompt: feedbackPrompt ?? this.feedbackPrompt,
      feedbackState: feedbackState ?? this.feedbackState,
      auditTrail: auditTrail ?? this.auditTrail,
    );
  }
}
