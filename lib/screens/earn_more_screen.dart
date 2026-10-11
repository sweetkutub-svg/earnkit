import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/task_model.dart';
import '../models/task_submission_model.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/banner_ad_widget.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_spacing.dart';

class EarnMoreScreen extends StatefulWidget {
  const EarnMoreScreen({super.key});

  @override
  State<EarnMoreScreen> createState() => _EarnMoreScreenState();
}

class _EarnMoreScreenState extends State<EarnMoreScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _fs = FirestoreService();
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  (Color, String) _chipInfo(
      AppTask task, TaskSubmission? sub, Map<String, int> counts) {
    final st = sub?.status;
    switch (st) {
      case null:
        return (AppColors.emerald, 'Apply');
      case SubmissionStatus.applied:
        return (AppColors.infoBlue, 'Applied');
      case SubmissionStatus.pending:
        return (AppColors.warningAmber, 'Pending');
      case SubmissionStatus.approved:
        return task.canRepeat(sub, counts)
            ? (AppColors.emerald, 'Do again')
            : (AppColors.successGreen, 'Completed');
      case SubmissionStatus.rejected:
        return (AppColors.errorRed, 'Rejected');
      case SubmissionStatus.expired:
        return (AppColors.gray600, 'Apply again');
    }
  }

  Widget _chip(Color color, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontWeight: FontWeight.w600, fontSize: 12)),
    );
  }

  Widget _statusChip(SubmissionStatus status) {
    final (color, label) = switch (status) {
      SubmissionStatus.applied => (AppColors.infoBlue, 'Applied'),
      SubmissionStatus.pending => (AppColors.warningAmber, 'Pending'),
      SubmissionStatus.approved => (AppColors.successGreen, 'Approved'),
      SubmissionStatus.rejected => (AppColors.errorRed, 'Rejected'),
      SubmissionStatus.expired => (AppColors.gray600, 'Expired'),
    };
    return _chip(color, label);
  }

  Widget _taskImage(String url) {
    final placeholder = Container(
      height: 160,
      width: double.infinity,
      color: AppColors.lightEmerald,
      child: const Center(
          child: Icon(Icons.task_alt, color: AppColors.emerald, size: 40)),
    );
    if (url.isEmpty) return placeholder;
    return Image.network(
      url,
      height: 160,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => placeholder,
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = AuthService().currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.emerald,
          indicatorColor: AppColors.emerald,
          tabs: const [
            Tab(text: 'Available Tasks'),
            Tab(text: 'My Submissions'),
          ],
        ),
      ),
      body: uid == null
          ? const Center(child: Text('Not logged in'))
          : StreamBuilder<List<AppTask>>(
              stream: _fs.streamActiveTasks(),
              builder: (context, tSnap) {
                if (tSnap.hasError) {
                  return Center(child: Text('Error: ${tSnap.error}'));
                }
                if (!tSnap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final tasks = [...tSnap.data!]..sort((a, b) {
                    final ca = a.code == 0 ? 1 << 30 : a.code;
                    final cb = b.code == 0 ? 1 << 30 : b.code;
                    return ca.compareTo(cb);
                  });

                return StreamBuilder<List<TaskSubmission>>(
                  stream: _fs.streamMySubmissions(uid),
                  builder: (context, sSnap) {
                    if (sSnap.hasError) {
                      return Center(child: Text('Error: ${sSnap.error}'));
                    }
                    if (!sSnap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final subs = sSnap.data!;

                    return StreamBuilder<Map<String, int>>(
                      stream: _fs.streamCompletedCounts(uid),
                      builder: (context, cSnap) {
                        final counts = cSnap.data ?? <String, int>{};
                        return TabBarView(
                          controller: _tabController,
                          children: [
                            _availableTab(tasks, subs, counts),
                            _submissionsTab(tasks, subs),
                          ],
                        );
                      },
                    );
                  },
                );
              },
            ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 2),
    );
  }

  // ---------- Available tasks ----------

  bool _matches(AppTask t) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return true;
    if (t.title.toLowerCase().contains(q)) return true;
    final digits = q.replaceAll(RegExp(r'\D'), '');
    if (digits.isNotEmpty && t.code > 0) {
      return t.code == int.tryParse(digits);
    }
    return false;
  }

  Widget _searchBox() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() => _query = v),
        decoration: InputDecoration(
          hintText: 'Search by task name or code (e.g. T-003)',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _query.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _query = '');
                  },
                ),
          isDense: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radius),
          ),
        ),
      ),
    );
  }

  Widget _emptyState(String title, String body) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.assignment_outlined,
                size: 64, color: AppColors.gray400),
            const SizedBox(height: AppSpacing.lg),
            Text(title,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: AppSpacing.sm),
            Text(body,
                textAlign: TextAlign.center, style: AppTextStyles.bodyText),
          ],
        ),
      ),
    );
  }

  Widget _availableTab(
      List<AppTask> tasks, List<TaskSubmission> subs, Map<String, int> counts) {
    if (tasks.isEmpty) {
      return _emptyState('No Tasks Available Yet', 'New tasks will appear here soon.');
    }

    final byTask = {for (final s in subs) s.taskId: s};
    final shown = tasks.where(_matches).toList();

    return Column(
      children: [
        _searchBox(),
        Expanded(
          child: shown.isEmpty
              ? _emptyState('No matching tasks', 'Try a different name or code.')
              : ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: shown.length + shown.length ~/ 3,
                  itemBuilder: (context, i) {
                    // One banner after every 3rd task.
                    if ((i + 1) % 4 == 0) {
                      return const Padding(
                        padding: EdgeInsets.only(
                            top: AppSpacing.sm, bottom: AppSpacing.lg),
                        child: Center(child: BannerAdWidget(labeled: true)),
                      );
                    }
                    final task = shown[i - (i + 1) ~/ 4];
                    final sub = byTask[task.id];
                    final (chipColor, chipLabel) = _chipInfo(task, sub, counts);
                    return InkWell(
                      borderRadius: BorderRadius.circular(AppSpacing.radius),
                      onTap: () => context.push('/task', extra: task),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radius),
                          border: Border.all(color: AppColors.gray200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(AppSpacing.radius)),
                              child: _taskImage(task.imageUrl),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (task.codeLabel.isNotEmpty)
                                          Text(
                                              '${task.codeLabel}  •  ${task.limitLabel}',
                                              style: AppTextStyles.caption
                                                  .copyWith(
                                                      color:
                                                          AppColors.emerald)),
                                        Text(task.title,
                                            style: AppTextStyles.h3CardTitle),
                                        const SizedBox(height: 4),
                                        Text(task.description,
                                            style: AppTextStyles.caption,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text('+${task.rewardPoints}',
                                          style: AppTextStyles.h3CardTitle
                                              .copyWith(
                                                  color: AppColors.emerald)),
                                      const SizedBox(height: 6),
                                      _chip(chipColor, chipLabel),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ---------- My submissions ----------

  String _subtitle(TaskSubmission s) {
    final left = (s.timeLeft != null) ? formatTimeLeft(s.timeLeft!) : '';
    switch (s.status) {
      case SubmissionStatus.applied:
        return 'Upload screenshot • $left';
      case SubmissionStatus.pending:
        return 'Verification pending';
      case SubmissionStatus.approved:
        return '+${s.rewardPoints} points credited';
      case SubmissionStatus.rejected:
        final reason = s.reviewNote.isNotEmpty ? s.reviewNote : 'Rejected';
        return '$reason • $left';
      case SubmissionStatus.expired:
        return 'Expired — apply again';
    }
  }

  Widget _submissionsTab(List<AppTask> tasks, List<TaskSubmission> subs) {
    if (subs.isEmpty) {
      return Center(
        child: Text('No submissions yet.', style: AppTextStyles.bodyText),
      );
    }
    final taskMap = {for (final t in tasks) t.id: t};

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: subs.length,
      itemBuilder: (context, i) {
        final s = subs[i];
        return InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.radius),
          onTap: () {
            final task = taskMap[s.taskId];
            if (task == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('This task is no longer available.')),
              );
              return;
            }
            context.push('/task', extra: task);
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppSpacing.radius),
              border: Border.all(color: AppColors.gray200),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: s.screenshotUrl.isNotEmpty
                      ? Image.network(s.screenshotUrl,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _thumbPlaceholder())
                      : _thumbPlaceholder(),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.taskTitle, style: AppTextStyles.h3CardTitle),
                      const SizedBox(height: 2),
                      Text(_subtitle(s),
                          style: AppTextStyles.caption,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                _statusChip(s.status),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _thumbPlaceholder() => Container(
        width: 48,
        height: 48,
        color: AppColors.lightEmerald,
        child: const Icon(Icons.task_alt, color: AppColors.emerald),
      );
}