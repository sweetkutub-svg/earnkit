import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_spacing.dart';

class SurveysScreen extends StatefulWidget {
  const SurveysScreen({super.key});

  @override
  State<SurveysScreen> createState() => _SurveysScreenState();
}

class _SurveysScreenState extends State<SurveysScreen> {
  static const _endpoint =
      'https://earnkit-backend.vercel.app/api/cpx-wall-url';

  WebViewController? _controller;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _controller = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) {
          setState(() {
            _loading = false;
            _error = 'Please log in again.';
          });
        }
        return;
      }

      final token = await user.getIdToken();
      final response = await http.post(
        Uri.parse(_endpoint),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode != 200) {
        var msg = 'Surveys are not available right now.';
        try {
          msg = (jsonDecode(response.body)['error'] ?? msg).toString();
        } catch (_) {}
        if (mounted) {
          setState(() {
            _loading = false;
            _error = msg;
          });
        }
        return;
      }

      final url = jsonDecode(response.body)['url'] as String;
      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.white)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageFinished: (_) {
              if (mounted) setState(() => _loading = false);
            },
            onWebResourceError: (e) {
              if ((e.isForMainFrame ?? true) && mounted) {
                setState(() {
                  _loading = false;
                  _error = 'Could not load surveys. Check your connection.';
                });
              }
            },
          ),
        )
        ..loadRequest(Uri.parse(url));

      if (mounted) setState(() => _controller = controller);
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Could not load surveys. Please try again.';
        });
      }
    }
  }

  void _leave() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final c = _controller;
        if (c != null && await c.canGoBack()) {
          await c.goBack();
        } else if (mounted) {
          _leave();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _leave,
          ),
          title: const Text('Surveys'),
        ),
        body: Column(
          children: [
            Container(
              width: double.infinity,
              color: AppColors.lightEmerald,
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
              child: Text(
                'Complete surveys to earn points. Points are added automatically after a survey is confirmed, which can take a few minutes.',
                style: AppTextStyles.caption,
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  if (_controller != null && _error == null)
                    WebViewWidget(controller: _controller!),
                  if (_loading)
                    const Center(child: CircularProgressIndicator()),
                  if (_error != null)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_error!,
                                textAlign: TextAlign.center,
                                style: AppTextStyles.bodyText),
                            const SizedBox(height: AppSpacing.md),
                            ElevatedButton(
                              onPressed: _load,
                              child: const Text('Try again'),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}