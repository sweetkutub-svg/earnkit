import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/task_model.dart';
import '../models/task_submission_model.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/skeleton.dart';
import '../theme/ui_colors.dart';

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
  bool _headerVisible = true;

  static const _blue = Color(0xFF3B7DD8);
  static const _amber = Color(0xFFD99A00);
  static const _green = Color(0xFF2E9E6B);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  (Color, String) _chipInfo(
    AppTask task,
    TaskSubmission? sub,
    Map<String, int> counts,
  ) {
    final st = sub?.status;
    switch (st) {
      case null:
        return (UiColors.sand, 'Apply');
      case SubmissionStatus.applied:
        return (_blue, 'Applied');
      case SubmissionStatus.pending:
        return (_amber, 'Pending');
      case SubmissionStatus.approved:
        return task.canRepeat(sub, counts)
            ? (UiColors.sand, 'Do again')
            : (_green, 'Completed');
      case SubmissionStatus.rejected:
        return (UiColors.danger, 'Rejected');
      case SubmissionStatus.expired:
        return (UiColors.muted, 'Apply again');
    }
  }

  Widget _chip(Color color, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _statusChip(SubmissionStatus status) {
    final (color, label) = switch (status) {
      SubmissionStatus.applied => (_blue, 'Applied'),
      SubmissionStatus.pending => (_amber, 'Pending'),
      SubmissionStatus.approved => (_green, 'Approved'),
      SubmissionStatus.rejected => (UiColors.danger, 'Rejected'),
      SubmissionStatus.expired => (UiColors.muted, 'Expired'),
    };
    return _chip(color, label);
  }

  Widget _taskImage(String url) {
    final placeholder = Container(
      height: 150,
      width: double.infinity,
      color: UiColors.mint,
      child: const Center(
        child: Icon(Icons.task_alt, color: UiColors.ink, size: 40),
      ),
    );
    if (url.isEmpty) return placeholder;
    return Image.network(
      url,
      height: 150,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => placeholder,
    );
  }

  // ---------- Collapsing header ----------

  /// Hides the App Offers / Surveys row on scroll down and shows it on scroll up.
  bool _onScroll(ScrollNotification n) {
    if (n.metrics.axis != Axis.vertical) return false;
    final m = n.metrics;
    bool? visible;
    if (m.pixels <= 8) {
      visible = true;
    } else if (n is ScrollUpdateNotification) {
      if ((n.scrollDelta ?? 0) > 2 && m.maxScrollExtent > 40) {
        visible = false;
      } else if ((n.scrollDelta ?? 0) < -2) {
        visible = true;
      }
    }
    if (visible != null && visible != _headerVisible && mounted) {
      setState(() => _headerVisible = visible!);
    }
    return false;
  }

  // ---------- Loading skeleton ----------

  Widget _tasksSkeleton() {
    return const Shimmer(
      child: SingleChildScrollView(
        physics: NeverScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(18, 16, 18, 24),
        child: Column(
          children: [
            SkeletonBox(height: 52, radius: 30),
            SizedBox(height: 16),
            SkeletonBox(height: 270, radius: 28),
            SizedBox(height: 16),
            SkeletonBox(height: 270, radius: 28),
          ],
        ),
      ),
    );
  }

  // ---------- Pinned offerwall row ----------

  Widget _offerTile({
    required Color color,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    String? badge,
  }) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: UiShadows.card,
        ),
        child: Material(
          color: color,
          borderRadius: BorderRadius.circular(28),
          child: InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, size: 22, color: UiColors.ink),
                      ),
                      const Spacer(),
                      if (badge != null) _chip(_amber, badge),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      color: UiColors.ink,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF55555A),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _offerRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _offerTile(
              color: UiColors.lilac,
              icon: Icons.download_for_offline_outlined,
              title: 'App Offers',
              subtitle: 'Install apps & earn',
              badge: 'Soon',
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('App offers are coming soon.')),
              ),
            ),
            const SizedBox(width: 12),
            _offerTile(
              color: UiColors.peach,
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

  // ---------- Toggle ----------

  Widget _toggle() {
    Widget seg(String label, bool value) {
      final selected = _showSubs == value;
      return Expanded(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() {
            _showSubs = value;
            _headerVisible = true;
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: selected ? UiColors.sand : Colors.transparent,
              borderRadius: BorderRadius.circular(26),
            ),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: selected ? UiColors.onSand : UiColors.muted,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: UiShadows.card,
        ),
        child: Row(
          children: [seg('Verified Tasks', false), seg('My Submissions', true)],
        ),
      ),
    );
  }

  // ---------- Build ----------

  @override
  Widget build(BuildContext context) {
    final uid = AuthService().currentUser?.uid;

    return Scaffold(
      backgroundColor: UiColors.bg,
      body: SafeArea(
        bottom: false,
        child: uid == null
            ? const Center(child: Text('Not logged in'))
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(18, 14, 18, 0),
                    child: Text(
                      'Tasks',
                      style: TextStyle(
                        fontSize: 30,
                        color: UiColors.ink,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  ClipRect(
                    child: AnimatedAlign(
                      alignment: Alignment.topCenter,
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      heightFactor: _headerVisible ? 1.0 : 0.0,
                      child: _offerRow(),
                    ),
                  ),
                  Expanded(
                    child: NotificationListener<ScrollNotification>(
                      onNotification: _onScroll,
                      child: _tasksArea(uid),
                    ),
                  ),
                ],
              ),
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
          return _tasksSkeleton();
        }
        final tasks = [...tSnap.data!]
          ..sort((a, b) {
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
              return _tasksSkeleton();
            }
            final subs = sSnap.data!;

            return StreamBuilder<Map<String, int>>(
              stream: _fs.streamCompletedCounts(uid),
              builder: (context, cSnap) {
                final counts = cSnap.data ?? <String, int>{};
                return Column(
                  children: [
                    _toggle(),
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
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: UiShadows.card,
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (v) => setState(() => _query = v),
          decoration: InputDecoration(
            hintText: 'Search by task name or code (e.g. T-003)',
            hintStyle: const TextStyle(
              fontSize: 13.5,
              color: UiColors.muted,
              fontWeight: FontWeight.w500,
            ),
            prefixIcon: const Icon(Icons.search, color: UiColors.muted),
            suffixIcon: _query.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.close, color: UiColors.muted),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _query = '');
                    },
                  ),
            filled: false,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _emptyState(String title, String body) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: const BoxDecoration(
                color: UiColors.lilac,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.assignment_outlined,
                size: 36,
                color: UiColors.ink,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                color: UiColors.ink,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              body,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: UiColors.muted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _overlayPill(String text, {Color color = Colors.white}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: UiShadows.card,
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12.5,
          color: UiColors.ink,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _taskCard(AppTask task, TaskSubmission? sub, Map<String, int> counts) {
    final (chipColor, chipLabel) = _chipInfo(task, sub, counts);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: UiShadows.card,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: () => context.push('/task', extra: task),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: _taskImage(task.imageUrl),
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: _overlayPill(
                        '+${task.rewardPoints} pts',
                        color: UiColors.lilac,
                      ),
                    ),
                    if (task.codeLabel.isNotEmpty)
                      Positioned(
                        top: 10,
                        left: 10,
                        child: _overlayPill(task.codeLabel),
                      ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 14, 8, 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: const TextStyle(
                          fontSize: 17,
                          height: 1.2,
                          color: UiColors.ink,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        task.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.35,
                          color: UiColors.muted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              task.limitLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: UiColors.muted,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 9,
                            ),
                            decoration: BoxDecoration(
                              color: chipColor,
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: Text(
                              chipLabel,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _availableTab(
    List<AppTask> tasks,
    List<TaskSubmission> subs,
    Map<String, int> counts,
  ) {
    if (tasks.isEmpty) {
      return _emptyState(
        'No Tasks Available Yet',
        'New tasks will appear here soon.',
      );
    }

    final byTask = {for (final s in subs) s.taskId: s};
    final shown = tasks.where(_matches).toList();

    return Column(
      children: [
        _searchBox(),
        Expanded(
          child: shown.isEmpty
              ? _emptyState(
                  'No matching tasks',
                  'Try a different name or code.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
                  itemCount: shown.length + 1,
                  itemBuilder: (context, i) {
                    final task = shown[i];
                    return _taskCard(task, byTask[task.id], counts);
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
      return _emptyState(
        'No submissions yet',
        'Tasks you apply for will show here.',
      );
    }
    final taskMap = {for (final t in tasks) t.id: t};

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
      itemCount: subs.length,
      itemBuilder: (context, i) {
        if (i == subs.length) return const SizedBox(height: 170); final s = subs[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: UiShadows.card,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () {
                final task = taskMap[s.taskId];
                if (task == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('This task is no longer available.'),
                    ),
                  );
                  return;
                }
                context.push('/task', extra: task);
              },
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: s.screenshotUrl.isNotEmpty
                          ? Image.network(
                              s.screenshotUrl,
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _thumbPlaceholder(),
                            )
                          : _thumbPlaceholder(),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.taskTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14.5,
                              color: UiColors.ink,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _subtitle(s),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: UiColors.muted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _statusChip(s.status),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _thumbPlaceholder() => Container(
    width: 56,
    height: 56,
    color: UiColors.mint,
    child: const Icon(Icons.task_alt, color: UiColors.ink),
  );
}
