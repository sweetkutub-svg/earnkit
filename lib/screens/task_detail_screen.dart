import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/task_model.dart';
import '../models/task_submission_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/cloudinary_service.dart';
import '../services/ad_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_spacing.dart';
import '../widgets/banner_ad_widget.dart';

class TaskDetailScreen extends StatefulWidget {
  final AppTask task;
  const TaskDetailScreen({super.key, required this.task});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final _auth = AuthService();
  final _fs = FirestoreService();
  final _cloudinary = CloudinaryService();
  File? _picked;
  bool _busy = false;
  static int _applyCount = 0;

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _apply() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    setState(() => _busy = true);
    try {
      _applyCount++;
      if (_applyCount % 3 == 0) {
        await AdService().watchGateAd();
      }
      await _fs.applyToTask(uid: uid, task: widget.task);
      _toast('Applied! Complete within ${widget.task.durationHours} hours.');
    } catch (e) {
      _toast('Apply failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1280,
    );
    if (picked != null) setState(() => _picked = File(picked.path));
  }

  Future<void> _submit() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    if (_picked == null) {
      _toast('Please select a screenshot first');
      return;
    }
    setState(() => _busy = true);
    try {
      final allowed = await AdService().watchGateAd();
      if (!allowed) {
        _toast('Please watch the full ad to submit your proof.');
        return;
      }
      final url = await _cloudinary.uploadImage(_picked!.path);
      if (url == null) {
        _toast('Upload failed, please try again');
        return;
      }
      await _fs.submitScreenshot(
        uid: uid,
        taskId: widget.task.id,
        screenshotUrl: url,
      );
      _picked = null;
      _toast('Submitted! Verification pending.');
    } catch (e) {
      _toast('Submit failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openLink() async {
    var link = widget.task.url.trim();
    if (link.isEmpty) {
      _toast('This task has no link.');
      return;
    }
    if (!link.startsWith('http://') && !link.startsWith('https://')) {
      link = 'https://$link';
    }
    final uri = Uri.tryParse(link);
    if (uri == null) {
      _toast('Invalid link.');
      return;
    }
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) _toast('Could not open the link.');
    } catch (_) {
      _toast('Could not open the link.');
    }
  }

  Widget _box({required Color color, required Widget child}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(AppSpacing.lg),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(AppSpacing.radius),
    ),
    child: child,
  );

  Widget _applyButton(String label) => SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      onPressed: _busy ? null : _apply,
      child: _busy
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Text(label),
    ),
  );

  Widget _uploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Upload proof screenshot', style: AppTextStyles.h3CardTitle),
        const SizedBox(height: AppSpacing.sm),
        GestureDetector(
          onTap: _busy ? null : _pickImage,
          child: Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.gray100,
              borderRadius: BorderRadius.circular(AppSpacing.radius),
              border: Border.all(color: AppColors.gray200),
            ),
            child: _picked != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(AppSpacing.radius),
                    child: Image.file(_picked!, fit: BoxFit.cover),
                  )
                : const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.upload_file,
                          color: AppColors.gray400,
                          size: 32,
                        ),
                        SizedBox(height: 8),
                        Text('Tap to select screenshot'),
                      ],
                    ),
                  ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _busy ? null : _submit,
            child: _busy
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Watch Ad & Submit'),
          ),
        ),
      ],
    );
  }

  Widget _actionSection(TaskSubmission? sub, Map<String, int> counts) {
    final task = widget.task;
    final st = sub?.status;

    // First time, or the previous attempt expired
    if (sub == null || st == SubmissionStatus.expired) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (st == SubmissionStatus.expired) ...[
            _box(
              color: AppColors.gray100,
              child: Text(
                'Your previous attempt expired. Apply again to get a new deadline.',
                style: AppTextStyles.bodyText,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          Text(
            'Complete within ${task.durationHours} hours after applying.',
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: AppSpacing.sm),
          _applyButton(
            st == SubmissionStatus.expired
                ? 'Apply Again (+${task.rewardPoints})'
                : 'Apply (+${task.rewardPoints})',
          ),
        ],
      );
    }

    if (st == SubmissionStatus.approved) {
      final done = task.doneCount(sub, counts);
      final canRepeat = task.canRepeat(sub, counts);
      final progress = task.isUnlimited
          ? 'Completed $done time${done == 1 ? '' : 's'}'
          : 'Completed $done of ${task.maxCompletions}';

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _box(
            color: AppColors.lightEmerald,
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: AppColors.emerald),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Approved — ${sub.rewardPoints} points credited',
                        style: AppTextStyles.h3CardTitle,
                      ),
                      const SizedBox(height: 2),
                      Text(progress, style: AppTextStyles.caption),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (canRepeat) ...[
            Text(
              'Complete within ${task.durationHours} hours after applying.',
              style: AppTextStyles.caption,
            ),
            const SizedBox(height: AppSpacing.sm),
            _applyButton('Do Again (+${task.rewardPoints})'),
          ] else
            Text(
              'You have reached the limit for this task.',
              style: AppTextStyles.caption,
            ),
        ],
      );
    }

    if (st == SubmissionStatus.pending) {
      return _box(
        color: AppColors.gray100,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.hourglass_empty, color: AppColors.gray600),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    'Submitted — verification pending',
                    style: AppTextStyles.h3CardTitle,
                  ),
                ),
              ],
            ),
            if (sub.screenshotUrl.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  sub.screenshotUrl,
                  height: 140,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ],
          ],
        ),
      );
    }

    // Applied, or rejected with time left
    final left = sub.timeLeft != null ? formatTimeLeft(sub.timeLeft!) : '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _box(
          color: AppColors.lightEmerald,
          child: Row(
            children: [
              const Icon(Icons.timer_outlined, color: AppColors.emerald),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  st == SubmissionStatus.rejected
                      ? 'Rejected — resubmit • $left'
                      : 'Applied — upload proof • $left',
                  style: AppTextStyles.h3CardTitle,
                ),
              ),
            ],
          ),
        ),
        if (st == SubmissionStatus.rejected && sub.reviewNote.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          _box(
            color: AppColors.errorRed.withValues(alpha: 0.08),
            child: Text(
              'Reason: ${sub.reviewNote}',
              style: AppTextStyles.bodyText.copyWith(color: AppColors.errorRed),
            ),
          ),
        ],
        if (task.url.trim().isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _openLink,
              icon: const Icon(Icons.open_in_new),
              label: const Text('Open Task Link'),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        _uploadSection(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final uid = _auth.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(title: Text(task.title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (task.imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radius),
                child: Image.network(
                  task.imageUrl,
                  width: double.infinity,
                  height: 190,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            const SizedBox(height: AppSpacing.md),
            if (task.codeLabel.isNotEmpty)
              Text(
                '${task.codeLabel}  •  ${task.limitLabel}',
                style: AppTextStyles.caption.copyWith(color: AppColors.emerald),
              ),
            Row(
              children: [
                Expanded(
                  child: Text(task.title, style: AppTextStyles.h2SectionHeader),
                ),
                Text(
                  '+${task.rewardPoints}',
                  style: AppTextStyles.h2SectionHeader.copyWith(
                    color: AppColors.emerald,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(task.description, style: AppTextStyles.bodyText),
            const SizedBox(height: AppSpacing.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.amberLight,
                borderRadius: BorderRadius.circular(AppSpacing.radius),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: AppColors.gold,
                    size: 18,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      task.note.isNotEmpty
                          ? task.note
                          : 'Complete the task and upload a screenshot as proof.',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.gold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (uid == null)
              const Text('Not logged in')
            else
              StreamBuilder<TaskSubmission?>(
                stream: _fs.streamSubmission(uid, task.id),
                builder: (context, snap) {
                  if (snap.hasError) {
                    return Text('Error: ${snap.error}');
                  }
                  if (snap.connectionState == ConnectionState.waiting &&
                      !snap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final sub = snap.data;
                  return StreamBuilder<Map<String, int>>(
                    stream: _fs.streamCompletedCounts(uid),
                    builder: (context, cSnap) =>
                        _actionSection(sub, cSnap.data ?? <String, int>{}),
                  );
                },
              ),
            const Divider(
              height: AppSpacing.xl,
              thickness: 1,
              color: AppColors.gray200,
            ),
            const Center(child: BannerAdWidget()),
          ],
        ),
      ),
    );
  }
}
