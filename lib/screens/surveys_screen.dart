import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';
import '../theme/ui_colors.dart';
import '../widgets/skeleton.dart';

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
              onTap: _leave,
              child: const Icon(Icons.arrow_back_rounded,
                  color: UiColors.ink, size: 22),
            ),
          ),
        ),
        const SizedBox(width: 14),
        const Text('Surveys',
            style: TextStyle(
                fontSize: 26,
                color: UiColors.ink,
                fontWeight: FontWeight.w800)),
      ],
    );
  }

  Widget _infoCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: UiColors.mint,
        borderRadius: BorderRadius.circular(24),
        boxShadow: UiShadows.card,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
                color: Colors.white, shape: BoxShape.circle),
            child: const Icon(Icons.poll_outlined,
                size: 19, color: UiColors.ink),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Complete surveys to earn points. Points are added automatically after a survey is confirmed, which can take a few minutes.',
              style: TextStyle(
                  fontSize: 12.5,
                  height: 1.35,
                  color: Color(0xFF2F4A41),
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _loadingPlaceholder() {
    return const ColoredBox(
      color: Colors.white,
      child: Shimmer(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonBox(width: 180, height: 22, radius: 8),
              SizedBox(height: 16),
              SkeletonBox(height: 84, radius: 20),
              SizedBox(height: 12),
              SkeletonBox(height: 84, radius: 20),
              SizedBox(height: 12),
              SkeletonBox(height: 84, radius: 20),
              SizedBox(height: 12),
              SkeletonBox(height: 84, radius: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _errorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                  color: UiColors.peach, shape: BoxShape.circle),
              child: const Icon(Icons.cloud_off_outlined,
                  color: UiColors.ink, size: 30),
            ),
            const SizedBox(height: 16),
            Text(_error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 14.5,
                    height: 1.4,
                    color: UiColors.ink,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 18),
            Material(
              color: UiColors.sand,
              borderRadius: BorderRadius.circular(40),
              elevation: 5,
              shadowColor: Colors.black.withValues(alpha: 0.3),
              child: InkWell(
                borderRadius: BorderRadius.circular(40),
                onTap: _load,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                  child: Text('Try again',
                      style: TextStyle(
                          fontSize: 15,
                          color: UiColors.onSand,
                          fontWeight: FontWeight.w800)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
        backgroundColor: UiColors.bg,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
                child: _header(),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
                child: _infoCard(),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: UiShadows.card,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: Stack(
                        children: [
                          if (_controller != null && _error == null)
                            Positioned.fill(
                                child: WebViewWidget(controller: _controller!)),
                          if (_loading && _error == null)
                            Positioned.fill(child: _loadingPlaceholder()),
                          if (_error != null)
                            Positioned.fill(child: _errorView()),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}