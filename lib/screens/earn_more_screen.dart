import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/task_model.dart';
import '../models/task_submission_model.dart';
import '../widgets/app_bottom_nav.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_spacing.dart';

class EarnMoreScreen extends StatefulWidget {
  const EarnMoreScreen({super.key});

  @override
  State<EarnMoreScreen> createState() => _EarnMoreScreenState();
}

class _EarnMoreScreenState extends State<EarnMoreScreen> {
  final _fs = FirestoreService();
  final _searchController = TextEditingController();
  String _query = '';
  bool _showSubs = false;

  @override
  void dispose() {
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

  // ---------- Pinned offerwall row ----------

    Widget _offerTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    String? badge,
  }) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radius),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppSpacing.radius),
            border: Border.all(color: AppColors.gray200),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 69,
                decoration: BoxDecoration(
                  color: AppColors.lightEmerald,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppColors.emerald, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(title,
                              style: AppTextStyles.h3CardTitle
                                  .copyWith(fontSize: 14),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color:
                                  AppColors.warningAmber.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text('Soon',
                                style: TextStyle(
                                    color: AppColors.warningAmber,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ],
                    ),
                    Text(subtitle,
                        style: AppTextStyles.caption.copyWith(fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _offerRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _offerTile(
              icon: Icons.download_for_offline_outlined,
              title: 'App Offers',
              subtitle: 'Install apps & earn more',
              badge: 'Soon',
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('App offers are coming soon.')),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            _offerTile(
              icon: Icons.poll_outlined,
              title: 'Surveys',
              subtitle: 'Rewards are estimates',
              onTap: () => context.push('/surveys'),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- Build ----------

  @override
  Widget build(BuildContext context) {
    final uid = AuthService().currentUser?.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Tasks')),
      body: uid == null
          ? const Center(child: Text('Not logged in'))
          : Column(
              children: [
                _offerRow(),
                Expanded(child: _tasksArea(uid)),
              ],
            ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 2),
    );
  }

  Widget _tasksArea(String uid) {
    return StreamBuilder<List<AppTask>>(
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
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
                      child: SizedBox(
                        width: double.infinity,
                        child: SegmentedButton<bool>(
                          showSelectedIcon: false,
                          segments: const [
                            ButtonSegment(
                                value: false, label: Text('Verified Tasks')),
                            ButtonSegment(
                                value: true, label: Text('My Submissions')),
                          ],
                          selected: {_showSubs},
                          onSelectionChanged: (s) =>
                              setState(() => _showSubs = s.first),
                        ),
                      ),
                    ),
                    Expanded(
                      child: _showSubs
                          ? _submissionsTab(tasks, subs)
                          : _availableTab(tasks, subs, counts),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
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
      return _emptyState(
          'No Tasks Available Yet', 'New tasks will appear here soon.');
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
                  itemCount: shown.length,
                  itemBuilder: (context, i) {
                    final task = shown[i];
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