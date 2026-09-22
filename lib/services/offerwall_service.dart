class OfferwallTask {
  final String id;
  final String title;
  final String category; // survey, download, signup
  final int rewardPoints;
  final String estimatedTime;
  final String difficulty; // Easy, Medium, Hard

  OfferwallTask({
    required this.id,
    required this.title,
    required this.category,
    required this.rewardPoints,
    required this.estimatedTime,
    required this.difficulty,
  });
}

/// Abstraction layer for offerwall networks (AdGate Media / AyetStudios).
/// Once a network account is approved, only THIS file needs to change —
/// the rest of the app talks to it through these methods only.
class OfferwallService {
  /// Returns available tasks. Currently returns an empty list because no
  /// offerwall network is connected yet (requires Play Store listing for
  /// approval — see 01_APP_ROADMAP.md Phase 12 notes). Once approved,
  /// this will call the network's SDK/API instead.
  Future<List<OfferwallTask>> fetchAvailableTasks() async {
    // TODO: replace with real network SDK call once approved
    return [];
  }

  /// Opens a specific task (webview or SDK flow). No-op until a network
  /// is connected.
  Future<void> openTask(OfferwallTask task) async {
    // TODO: implement once a network SDK is integrated
  }
}