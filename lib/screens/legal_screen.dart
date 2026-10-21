import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../theme/ui_colors.dart';
import '../widgets/skeleton.dart';

/// Shows admin-editable legal text from Firestore: app_config/legal.
/// Formatting: "# Heading" = heading, "- item" = bullet, anything else = paragraph.
class LegalScreen extends StatefulWidget {
  final String title;
  final String field; // 'privacyPolicy' or 'termsOfService'

  const LegalScreen({super.key, required this.title, required this.field});

  @override
  State<LegalScreen> createState() => _LegalScreenState();
}

class _LegalScreenState extends State<LegalScreen> {
  static const _fallback =
      '# Not available\nThis document could not be loaded. Please check your connection and try again.';

  // Created once so the text isn't re-fetched on every rebuild.
  late final Future<String> _future = _load();

  Future<String> _load() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('app_config')
          .doc('legal')
          .get();
      final text = (snap.data()?[widget.field] as String?)?.trim() ?? '';
      return text.isEmpty ? _fallback : text;
    } catch (_) {
      return _fallback;
    }
  }

  List<Widget> _build(String text) {
    final widgets = <Widget>[];
    for (final raw in text.split('\n')) {
      final line = raw.trimRight();
      if (line.trim().isEmpty) {
        widgets.add(const SizedBox(height: 8));
      } else if (line.startsWith('# ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 18, bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 5,
                height: 22,
                margin: const EdgeInsets.only(right: 10, top: 1),
                decoration: BoxDecoration(
                  color: UiColors.sand,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              Expanded(
                child: Text(line.substring(2),
                    style: const TextStyle(
                        fontSize: 17,
                        height: 1.3,
                        color: UiColors.ink,
                        fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        ));
      } else if (line.startsWith('- ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 7,
                height: 7,
                margin: const EdgeInsets.only(top: 8, right: 10),
                decoration: const BoxDecoration(
                  color: UiColors.sand,
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(
                child: Text(line.substring(2),
                    style: const TextStyle(
                        fontSize: 14,
                        height: 1.55,
                        color: Color(0xFF3A3A3F),
                        fontWeight: FontWeight.w500)),
              ),
            ],
          ),
        ));
      } else {
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(line,
              style: const TextStyle(
                  fontSize: 14,
                  height: 1.55,
                  color: Color(0xFF3A3A3F),
                  fontWeight: FontWeight.w500)),
        ));
      }
    }
    return widgets;
  }

  Widget _backButton() {
    return Container(
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
    );
  }

  Widget _skeleton() {
    return const Shimmer(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonBox(width: 190, height: 22, radius: 8),
            SizedBox(height: 16),
            SkeletonBox(height: 14, radius: 6),
            SizedBox(height: 10),
            SkeletonBox(height: 14, radius: 6),
            SizedBox(height: 10),
            SkeletonBox(width: 240, height: 14, radius: 6),
            SizedBox(height: 26),
            SkeletonBox(width: 150, height: 22, radius: 8),
            SizedBox(height: 16),
            SkeletonBox(height: 14, radius: 6),
            SizedBox(height: 10),
            SkeletonBox(height: 14, radius: 6),
            SizedBox(height: 10),
            SkeletonBox(width: 200, height: 14, radius: 6),
            SizedBox(height: 10),
            SkeletonBox(height: 14, radius: 6),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      backgroundColor: UiColors.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
              child: Row(
                children: [
                  if (canPop) ...[
                    _backButton(),
                    const SizedBox(width: 14),
                  ],
                  Expanded(
                    child: Text(widget.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 26,
                            color: UiColors.ink,
                            fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: UiShadows.card,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: FutureBuilder<String>(
                      future: _future,
                      builder: (context, snap) {
                        if (snap.connectionState != ConnectionState.done) {
                          return _skeleton();
                        }
                        return SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: _build(snap.data ?? _fallback),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}