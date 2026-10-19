import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../theme/ui_colors.dart';

/// Shows progress towards unlocking the signup bonus.
/// Only points earned from ads count.
class UnlockProgress extends StatefulWidget {
  final int adPoints;
  const UnlockProgress({super.key, required this.adPoints});

  @override
  State<UnlockProgress> createState() => _UnlockProgressState();
}

class _UnlockProgressState extends State<UnlockProgress> {
  static const _green = Color(0xFF2E9E6B);
  int _threshold = 450;

  @override
  void initState() {
    super.initState();
    _loadThreshold();
  }

  Future<void> _loadThreshold() async {
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
    final reached = widget.adPoints >= _threshold;
    final color = reached ? _green : UiColors.danger;
    final progress = (widget.adPoints / _threshold).clamp(0.0, 1.0).toDouble();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: UiShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  reached ? Icons.lock_open_rounded : Icons.lock_outline,
                  size: 19,
                  color: color,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  reached
                      ? 'Bonus unlocked: ${widget.adPoints} / $_threshold'
                      : 'Watch ads to unlock your bonus: ${widget.adPoints} / $_threshold',
                  style: TextStyle(
                      fontSize: 14,
                      color: color,
                      fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 9,
              backgroundColor: UiColors.bg,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Only points from watching ads count. Surveys and tasks do not.',
            style: TextStyle(
                fontSize: 12,
                color: UiColors.muted,
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}