import 'task_submission_model.dart';

class AppTask {
  final String id;
  final String title;
  final String description;
  final String note;
  final String imageUrl;
  final int rewardPoints;
  final String url;
  final bool active;
  final int durationHours;
  final int code;
  final int maxCompletions; // 0 = unlimited

  AppTask({
    required this.id,
    required this.title,
    required this.description,
    required this.note,
    required this.imageUrl,
    required this.rewardPoints,
    required this.url,
    required this.active,
    required this.durationHours,
    required this.code,
    required this.maxCompletions,
  });

  factory AppTask.fromMap(String id, Map<String, dynamic> map) {
    return AppTask(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      note: map['note'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      rewardPoints: ((map['rewardPoints'] ?? 0) as num).toInt(),
      url: map['url'] ?? '',
      active: map['active'] ?? true,
      durationHours: ((map['durationHours'] ?? 24) as num).toInt(),
      code: ((map['code'] ?? 0) as num).toInt(),
      maxCompletions: ((map['maxCompletions'] ?? 1) as num).toInt(),
    );
  }

  String get codeLabel =>
      code > 0 ? 'T-${code.toString().padLeft(3, '0')}' : '';

  bool get isUnlimited => maxCompletions == 0;

  String get limitLabel {
    if (isUnlimited) return 'Repeatable';
    if (maxCompletions == 1) return 'One-time';
    return 'Up to $maxCompletions times';
  }
}

extension TaskRepeat on AppTask {
  /// An approved submission counts as one completion even if no progress record exists.
  int doneCount(TaskSubmission? sub, Map<String, int> counts) =>
      counts[id] ?? (sub?.status == SubmissionStatus.approved ? 1 : 0);

  bool canRepeat(TaskSubmission? sub, Map<String, int> counts) =>
      isUnlimited || doneCount(sub, counts) < maxCompletions;
}