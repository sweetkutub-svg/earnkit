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
import '../theme/ui_colors.dart';

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

  static const _green = Color(0xFF2E9E6B);

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

  // ---------- UI helpers ----------

  Widget _box({required Color color, required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(22),
          boxShadow: UiShadows.card,
        ),
        child: child,
      );

  Widget _caption(String text) => Text(text,
      style: const TextStyle(
          fontSize: 12.5, color: UiColors.muted, fontWeight: FontWeight.w600));

  Widget _boxTitle(String text) => Text(text,
      style: const TextStyle(
          fontSize: 14.5, color: UiColors.ink, fontWeight: FontWeight.w800));

  Widget _spinner() => const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
      );

  Widget _applyButton(String label) => SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _busy ? null : _apply,
          child: _busy ? _spinner() : Text(label),
        ),
      );

  Widget _uploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Upload proof screenshot',
            style: TextStyle(
                fontSize: 17, color: UiColors.ink, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: _busy ? null : _pickImage,
          child: Container(
            height: 170,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: UiShadows.card,
            ),
            child: _picked != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.file(_picked!, fit: BoxFit.cover),
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          decoration: const BoxDecoration(
                              color: UiColors.lilac, shape: BoxShape.circle),
                          child: const Icon(Icons.upload_file,
                              color: UiColors.ink, size: 26),
                        ),
                        const SizedBox(height: 10),
                        const Text('Tap to select screenshot',
                            style: TextStyle(
                                fontSize: 13.5,
                                color: UiColors.muted,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _busy ? null : _submit,
            child: _busy ? _spinner() : const Text('Watch Ad & Submit'),
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
              color: Colors.white,
              child: const Text(
                'Your previous attempt expired. Apply again to get a new deadline.',
                style: TextStyle(
                    fontSize: 13.5,
                    color: UiColors.ink,
                    fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 14),
          ],
          _caption('Complete within ${task.durationHours} hours after applying.'),
          const SizedBox(height: 10),
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
            color: UiColors.mint,
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                      color: Colors.white, shape: BoxShape.circle),
                  child: const Icon(Icons.check_rounded, color: _green),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _boxTitle(
                          'Approved — ${sub.rewardPoints} points credited'),
                      const SizedBox(height: 2),
                      _caption(progress),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (canRepeat) ...[
            _caption(
                'Complete within ${task.durationHours} hours after applying.'),
            const SizedBox(height: 10),
            _applyButton('Do Again (+${task.rewardPoints})'),
          ] else
            _caption('You have reached the limit for this task.'),
        ],
      );
    }

    if (st == SubmissionStatus.pending) {
      return _box(
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                      color: UiColors.peach, shape: BoxShape.circle),
                  child: const Icon(Icons.hourglass_empty,
                      color: UiColors.ink, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(child: _boxTitle('Submitted — verification pending')),
              ],
            ),
            if (sub.screenshotUrl.isNotEmpty) ...[
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  sub.screenshotUrl,
                  height: 150,
                  width: double.infinity,
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
          color: UiColors.lilac,
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                    color: Colors.white, shape: BoxShape.circle),
                child: const Icon(Icons.timer_outlined,
                    color: UiColors.ink, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _boxTitle(
                  st == SubmissionStatus.rejected
                      ? 'Rejected — resubmit • $left'
                      : 'Applied — upload proof • $left',
                ),
              ),
            ],
          ),
        ),
        if (st == SubmissionStatus.rejected && sub.reviewNote.isNotEmpty) ...[
          const SizedBox(height: 12),
          _box(
            color: Colors.white,
            child: Text(
              'Reason: ${sub.reviewNote}',
              style: const TextStyle(
                  fontSize: 13.5,
                  color: UiColors.danger,
                  fontWeight: FontWeight.w700),
            ),
          ),
        ],
        if (task.url.trim().isNotEmpty) ...[
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _openLink,
              icon: const Icon(Icons.open_in_new, size: 18),
              label: const Text('Open Task Link'),
            ),
          ),
        ],
        const SizedBox(height: 20),
        _uploadSection(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final uid = _auth.currentUser?.uid;

    return Scaffold(
      backgroundColor: UiColors.bg,
      appBar: AppBar(title: const Text('Task details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 6, 18, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (task.imageUrl.isNotEmpty)
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: UiShadows.card,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.network(
                    task.imageUrl,
                    width: double.infinity,
                    height: 190,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ),
            if (task.imageUrl.isNotEmpty) const SizedBox(height: 16),

            // Title card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: UiShadows.card,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (task.codeLabel.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '${task.codeLabel}  •  ${task.limitLabel}',
                        style: const TextStyle(
                            fontSize: 12,
                            color: UiColors.sand,
                            fontWeight: FontWeight.w800),
                      ),
                    ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(task.title,
                            style: const TextStyle(
                                fontSize: 20,
                                height: 1.2,
                                color: UiColors.ink,
                                fontWeight: FontWeight.w800)),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: UiColors.lilac,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text('+${task.rewardPoints}',
                            style: const TextStyle(
                                fontSize: 15,
                                color: UiColors.ink,
                                fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(task.description,
                      style: const TextStyle(
                          fontSize: 14,
                          height: 1.4,
                          color: Color(0xFF55555A),
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: UiColors.peach,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline,
                            color: UiColors.ink, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            task.note.isNotEmpty
                                ? task.note
                                : 'Complete the task and upload a screenshot as proof.',
                            style: const TextStyle(
                                fontSize: 12.5,
                                color: UiColors.ink,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

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
          ],
        ),
      ),
    );
  }
}