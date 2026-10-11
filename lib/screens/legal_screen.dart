import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Shows admin-editable legal text from Firestore: app_config/legal.
/// Formatting: "# Heading" = heading, "- item" = bullet, anything else = paragraph.
class LegalScreen extends StatelessWidget {
  final String title;
  final String field; // 'privacyPolicy' or 'termsOfService'

  const LegalScreen({super.key, required this.title, required this.field});

  static const _fallback =
      '# Not available\nThis document could not be loaded. Please check your connection and try again.';

  Future<String> _load() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('app_config')
          .doc('legal')
          .get();
      final text = (snap.data()?[field] as String?)?.trim() ?? '';
      return text.isEmpty ? _fallback : text;
    } catch (_) {
      return _fallback;
    }
  }

  List<Widget> _build(BuildContext context, String text) {
    final theme = Theme.of(context);
    final widgets = <Widget>[];
    for (final raw in text.split('\n')) {
      final line = raw.trimRight();
      if (line.trim().isEmpty) {
        widgets.add(const SizedBox(height: 8));
      } else if (line.startsWith('# ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 6),
          child: Text(line.substring(2),
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
        ));
      } else if (line.startsWith('- ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('•  '),
              Expanded(
                  child: Text(line.substring(2),
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.5))),
            ],
          ),
        ));
      } else {
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(line,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.5)),
        ));
      }
    }
    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: FutureBuilder<String>(
        future: _load(),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _build(context, snap.data ?? _fallback),
            ),
          );
        },
      ),
    );
  }
}