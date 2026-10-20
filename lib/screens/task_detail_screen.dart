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
import '../widgets/skeleton.dart';

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
          borderRadius: BorderRadius.circular(24),
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

  Widget _pill(String label, VoidCallback? onTap, {bool loading = false}) {
    final enabled = onTap != null;
    return Material(
      color: enabled ? UiColors.sand : UiColors.disabled,
      borderRadius: BorderRadius.circular(40),
      elevation: enabled ? 5 : 0,
      shadowColor: Colors.black.withValues(alpha: 0.3),
      child: InkWell(
        borderRadius: BorderRadius.circular(40),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Center(
            child: loading
                ? _spinner()
                : Text(label,
                    style: const TextStyle(
                        fontSize: 15,
                        color: UiColors.onSand,
                        fontWeight: FontWeight.w800)),
          ),
        ),
      ),
    );
  }

  Widget _applyButton(String label) =>
      _pill(label, _busy ? null : _apply, loading: _busy);

  Widget _iconBubble(IconData icon, Color color) => Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Icon(icon, color: UiColors.ink, size: 20),
      );

  Widget _uploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Upload proof screenshot',
            style: TextStyle(
                fontSize: 18, color: UiColors.ink, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: _busy ? null : _pickImage,
          child: Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: UiShadows.card,
            ),
            child: _picked != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Image.file(_picked!, fit: BoxFit.cover),
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 58,
                          height: 58,
                          decoration: const BoxDecoration(
                              color: UiColors.lilac, shape: BoxShape.circle),
                          child: const Icon(Icons.upload_file,
                              color: UiColors.ink, size: 28),
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
        _pill('Watch Ad & Submit', _busy ? null : _submit, loading: _busy),
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
              color: UiColors.peach,
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
                _iconBubble(Icons.hourglass_empty, UiColors.peach),
                const SizedBox(width: 12),
                Expanded(child: _boxTitle('Submitted — verification pending')),
              ],
            ),
            if (sub.screenshotUrl.isNotEmpty) ...[
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(
                  sub.screenshotUrl,
                  height: 160,
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
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(40),
            elevation: 3,
            shadowColor: Colors.black.withValues(alpha: 0.2),
            child: InkWell(
              borderRadius: BorderRadius.circular(40),
              onTap: _openLink,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.open_in_new, size: 18, color: UiColors.sand),
                    SizedBox(width: 8),
                    Text('Open Task Link',
                        style: TextStyle(
                            fontSize: 15,
                            color: UiColors.sand,
                            fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 22),
        _uploadSection(),
      ],
    );
  }

  Widget _header() {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: UiShadows.card,
          ),
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => Navigator.of(context).maybePop(),
              child: const Icon(Icons.arrow_back_rounded,
                  color: UiColors.ink, size: 22),
            ),
          ),
        ),
        const SizedBox(width: 14),
        const Text('Task details',
            style: TextStyle(
                fontSize: 24,
                color: UiColors.ink,
                fontWeight: FontWeight.w800)),
      ],
    );
  }

  Widget _miniStat(Color color, IconData icon, String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: UiColors.ink),
            const SizedBox(height: 8),
            Text(value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 15,
                    color: UiColors.ink,
                    fontWeight: FontWeight.w800)),
            Text(label,
                style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF55555A),
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final uid = _auth.currentUser?.uid;

    return Scaffold(
      backgroundColor: UiColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _header(),
              const SizedBox(height: 16),
              if (task.imageUrl.isNotEmpty) ...[
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: UiShadows.card,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Image.network(
                      task.imageUrl,
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Title card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: UiShadows.card,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (task.codeLabel.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          task.codeLabel,
                          style: const TextStyle(
                              fontSize: 12,
                              color: UiColors.sand,
                              fontWeight: FontWeight.w800),
                        ),
                      ),
                    Text(task.title,
                        style: const TextStyle(
                            fontSize: 22,
                            height: 1.2,
                            color: UiColors.ink,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 10),
                    Text(task.description,
                        style: const TextStyle(
                            fontSize: 14,
                            height: 1.45,
                            color: Color(0xFF55555A),
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _miniStat(UiColors.lilac, Icons.stars_outlined, 'Reward',
                            '+${task.rewardPoints}'),
                        const SizedBox(width: 10),
                        _miniStat(UiColors.mint, Icons.timer_outlined,
                            'To finish', '${task.durationHours}h'),
                        if (task.limitLabel.isNotEmpty) ...[
                          const SizedBox(width: 10),
                          _miniStat(UiColors.peach, Icons.repeat, 'Limit',
                              task.limitLabel),
                        ],
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: UiColors.bg,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline,
                              color: UiColors.sand, size: 18),
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
                      return const Shimmer(
                        child: Column(
                          children: [
                            SkeletonBox(height: 72, radius: 24),
                            SizedBox(height: 14),
                            SkeletonBox(height: 52, radius: 40),
                          ],
                        ),
                      );
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
      ),
    );
  }
}