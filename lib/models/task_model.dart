class AppTask {
  final String id;
  final String title;
  final String description;
  final int rewardPoints;
  final String url;
  final bool active;

  AppTask({
    required this.id,
    required this.title,
    required this.description,
    required this.rewardPoints,
    required this.url,
    required this.active,
  });

  factory AppTask.fromMap(String id, Map<String, dynamic> map) {
    return AppTask(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      rewardPoints: (map['rewardPoints'] ?? 0) as int,
      url: map['url'] ?? '',
      active: map['active'] ?? true,
    );
  }
}