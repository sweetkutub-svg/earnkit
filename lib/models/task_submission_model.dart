import 'package:cloud_firestore/cloud_firestore.dart';

enum SubmissionStatus { applied, pending, approved, rejected, expired }

String formatTimeLeft(Duration d) {
  if (d.isNegative) return 'Expired';
  final h = d.inHours;
  final m = d.inMinutes % 60;
  if (h >= 24) return '${d.inDays}d ${h % 24}h left';
  if (h > 0) return '${h}h ${m}m left';
  return '${m}m left';
}

class TaskSubmission {
  final String id;
  final String uid;
  final String taskId;
  final String taskTitle;
  final int rewardPoints;
  final String screenshotUrl;
  final String rawStatus;
  final DateTime? appliedAt;
  final DateTime? submittedAt;
  final DateTime? expiresAt;
  final String reviewNote;

  TaskSubmission({
    required this.id,
    required this.uid,
    required this.taskId,
    required this.taskTitle,
    required this.rewardPoints,
    required this.screenshotUrl,
    required this.rawStatus,
    required this.appliedAt,
    required this.submittedAt,
    required this.expiresAt,
    required this.reviewNote,
  });

  factory TaskSubmission.fromMap(String id, Map<String, dynamic> map) {
    return TaskSubmission(
      id: id,
      uid: map['uid'] ?? '',
      taskId: map['taskId'] ?? '',
      taskTitle: map['taskTitle'] ?? '',
      rewardPoints: ((map['rewardPoints'] ?? 0) as num).toInt(),
      screenshotUrl: map['screenshotUrl'] ?? '',
      rawStatus: map['status'] ?? 'pending',
      appliedAt: (map['appliedAt'] as Timestamp?)?.toDate(),
      submittedAt: (map['submittedAt'] as Timestamp?)?.toDate(),
      expiresAt: (map['expiresAt'] as Timestamp?)?.toDate(),
      reviewNote: map['reviewNote'] ?? '',
    );
  }

  static SubmissionStatus _parse(String v) {
    switch (v) {
      case 'applied':
        return SubmissionStatus.applied;
      case 'approved':
        return SubmissionStatus.approved;
      case 'rejected':
        return SubmissionStatus.rejected;
      default:
        return SubmissionStatus.pending;
    }
  }

  /// applied / rejected + deadline nikal gayi = expired (client-side computed)
  SubmissionStatus get status {
    final raw = _parse(rawStatus);
    if ((raw == SubmissionStatus.applied || raw == SubmissionStatus.rejected) &&
        expiresAt != null &&
        DateTime.now().isAfter(expiresAt!)) {
      return SubmissionStatus.expired;
    }
    return raw;
  }

  Duration? get timeLeft => expiresAt?.difference(DateTime.now());

  DateTime get sortTime => submittedAt ?? appliedAt ?? DateTime.now();
}