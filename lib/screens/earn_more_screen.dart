import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/offerwall_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_spacing.dart';

class EarnMoreScreen extends StatefulWidget {
  const EarnMoreScreen({super.key});

  @override
  State<EarnMoreScreen> createState() => _EarnMoreScreenState();
}

class _EarnMoreScreenState extends State<EarnMoreScreen> {
  final _offerwallService = OfferwallService();
  List<OfferwallTask> _tasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final tasks = await _offerwallService.fetchAvailableTasks();
    if (!mounted) return;
    setState(() {
      _tasks = tasks;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: const Text('Earn More'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _tasks.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.assignment_outlined,
                          size: 64, color: AppColors.gray400),
                      const SizedBox(height: AppSpacing.lg),
                      const Text(
                        'No Tasks Available Yet',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Surveys, app installs, and other tasks will appear here once available. Check back soon!',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyText,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: _tasks.length,
                  itemBuilder: (context, index) {
                    final task = _tasks[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radius),
                        border: Border.all(color: AppColors.gray200),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(task.title,
                                    style: AppTextStyles.h3CardTitle),
                                Text(
                                  '~${task.estimatedTime} • ${task.difficulty}',
                                  style: AppTextStyles.caption,
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('+${task.rewardPoints}',
                                  style: AppTextStyles.h3CardTitle
                                      .copyWith(color: AppColors.emerald)),
                              ElevatedButton(
                                onPressed: () =>
                                    _offerwallService.openTask(task),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                ),
                                child: const Text('Start'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}