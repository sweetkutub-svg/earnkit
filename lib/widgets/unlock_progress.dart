import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_spacing.dart';

/// Shows how many ad points are still needed to unlock the signup bonus.
/// Threshold comes from app_config/reward_config (read once).
class UnlockProgress extends StatefulWidget {
  final int adPoints;
  const UnlockProgress({super.key, required this.adPoints});

  @override
  State<UnlockProgress> createState() => _UnlockProgressState();
}

class _UnlockProgressState extends State<UnlockProgress> {
  int _threshold = 450;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('app_config')
          .doc('reward_config')
          .get();
      final v = snap.data()?['bonusUnlockThreshold'];
      if (v is num && v > 0 && mounted) {
        setState(() => _threshold = v.toInt());
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final done = widget.adPoints.clamp(0, _threshold);
    final reached = widget.adPoints >= _threshold;
    final color = reached ? AppColors.successGreen : AppColors.errorRed;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radius),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            reached
                ? 'Bonus unlocked: $done / $_threshold'
                : 'Watch ads to unlock your bonus: $done / $_threshold',
            style: AppTextStyles.caption
                .copyWith(color: color, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: _threshold == 0 ? 1 : done / _threshold,
              minHeight: 8,
              backgroundColor: color.withValues(alpha: 0.15),
              color: color,
            ),
          ),
          const SizedBox(height: 6),
          Text('Only points from watching ads count. Surveys and tasks do not.',
              style: AppTextStyles.caption),
        ],
      ),
    );
  }
}