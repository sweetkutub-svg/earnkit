import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/remote_config_service.dart';
import '../theme/ui_colors.dart';
import 'maintenance_screen.dart';
import 'force_update_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  final _authService = AuthService();
  final _remoteConfigService = RemoteConfigService();
  Widget? _blockingScreen;

  static const _title = 'Earnkit';
  static const _introMs = 2600;

  // One-shot intro + endless loop (rings, bobbing chips, loader)
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: _introMs),
  )..forward();
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  )..repeat();

  final Stopwatch _clock = Stopwatch()..start();

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _intro.dispose();
    _loop.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final config = await _remoteConfigService.fetchConfig();

    if (config.maintenanceMode) {
      if (mounted) {
        setState(() {
          _blockingScreen =
              MaintenanceScreen(message: config.maintenanceMessage);
        });
      }
      return;
    }

    final needsUpdate =
        await _remoteConfigService.isUpdateRequired(config.minRequiredVersion);
    if (needsUpdate) {
      if (mounted) {
        setState(() {
          _blockingScreen = ForceUpdateScreen(message: config.updateMessage);
        });
      }
      return;
    }

    // Let the intro finish, without adding extra wait if the network calls
    // above already took longer.
    final left = _introMs - _clock.elapsedMilliseconds;
    if (left > 0) await Future.delayed(Duration(milliseconds: left));
    if (!mounted) return;

    final user = _authService.currentUser;
    if (user == null) {
      context.go('/onboarding');
      return;
    }

    // Check ban status before anything else
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    if (userDoc.exists && (userDoc.data()?['banned'] == true)) {
      await _authService.signOut();
      if (mounted) {
        setState(() {
          _blockingScreen = MaintenanceScreen(
            message:
                'Your account has been suspended. Contact support if you believe this is a mistake.',
          );
        });
      }
      return;
    }

    if (!_authService.isEmailVerified) {
      context.go('/verify-email');
    } else {
      context.go('/home');
    }
  }

  /// 0..1 progress of the intro between [a] and [b], eased.
  double _p(double a, double b, [Curve curve = Curves.easeOut]) {
    final t = ((_intro.value - a) / (b - a)).clamp(0.0, 1.0);
    return curve.transform(t);
  }

  // ---------- Pieces ----------

  Widget _mascot() {
    final v = _p(0.12, 0.55, Curves.easeOutBack);
    final fade = _p(0.12, 0.35).clamp(0.0, 1.0);
    final float = math.sin(_loop.value * 2 * math.pi) * 4;

    return Opacity(
      opacity: fade,
      child: Transform.translate(
        offset: Offset(0, (1 - v) * 30 + float),
        child: Transform.scale(
          scale: 0.5 + 0.5 * v,
          child: Container(
            width: 176,
            height: 176,
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.28),
                  blurRadius: 34,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/images/splash_mascot.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const ColoredBox(
                  color: UiColors.mint,
                  child: Icon(Icons.bolt_rounded,
                      size: 70, color: UiColors.ink),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _rings() {
    final fade = _p(0.1, 0.5);
    return OverflowBox(
      maxWidth: 560,
      maxHeight: 560,
      child: SizedBox(
        width: 560,
        height: 560,
        child: CustomPaint(
          painter: _RingsPainter(t: _loop.value, fade: fade),
        ),
      ),
    );
  }

  Widget _chip({
    required Color color,
    required IconData icon,
    required String text,
    required Alignment align,
    required double start,
    required double phase,
  }) {
    final v = _p(start, start + 0.22, Curves.easeOutBack);
    final bob = math.sin(_loop.value * 2 * math.pi + phase) * 5;

    return Align(
      alignment: align,
      child: Opacity(
        opacity: v.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, bob),
          child: Transform.scale(
            scale: v,
            child: Container(
              padding: const EdgeInsets.fromLTRB(7, 7, 14, 7),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.22),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 16, color: UiColors.ink),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    text,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: UiColors.ink,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sheet(double width, double height) {
    final v = _p(0.0, 0.42, Curves.easeOutCubic);

    return Transform.translate(
      offset: Offset(0, -(1 - v) * height),
      child: Container(
        width: width,
        height: height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF61768A), UiColors.sand],
          ),
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(52)),
          boxShadow: UiShadows.card,
        ),
        child: ClipRRect(
          borderRadius:
              const BorderRadius.vertical(bottom: Radius.circular(52)),
          child: Stack(
            children: [
              // Faint decorative circles
              Positioned(
                top: -70,
                right: -60,
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
              ),
              Positioned(
                bottom: -90,
                left: -70,
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
              ),

              // Pulse rings + mascot (same centre)
              Align(alignment: const Alignment(0, 0.08), child: _rings()),
              Align(alignment: const Alignment(0, 0.08), child: _mascot()),

              // Floating pastel chips
              _chip(
                color: UiColors.mint,
                icon: Icons.play_circle_outline,
                text: 'Watch & Earn',
                align: const Alignment(-0.88, -0.52),
                start: 0.50,
                phase: 0,
              ),
              _chip(
                color: UiColors.lilac,
                icon: Icons.bolt_rounded,
                text: 'Instant UPI',
                align: const Alignment(0.92, 0.02),
                start: 0.60,
                phase: 2.1,
              ),
              _chip(
                color: UiColors.peach,
                icon: Icons.people_outline,
                text: 'Refer & Earn',
                align: const Alignment(-0.7, 0.72),
                start: 0.70,
                phase: 4.2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _titleText() {
    final letters = <Widget>[];
    for (var i = 0; i < _title.length; i++) {
      final start = 0.46 + i * 0.04;
      final v = _p(start, start + 0.2, Curves.easeOutCubic);
      letters.add(
        Opacity(
          opacity: v.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, (1 - v) * 18),
            child: Text(
              _title[i],
              style: const TextStyle(
                fontSize: 44,
                height: 1.1,
                fontWeight: FontWeight.w800,
                color: UiColors.ink,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      );
    }

    final sweep = _p(0.72, 1.0, Curves.easeInOut);

    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (rect) => LinearGradient(
        colors: const [UiColors.ink, Color(0xFF7C8E9C), UiColors.ink],
        stops: const [0.35, 0.5, 0.65],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        transform: _SlideGradient(sweep),
      ).createShader(rect),
      child: Row(mainAxisSize: MainAxisSize.min, children: letters),
    );
  }

  Widget _tagline() {
    final v = _p(0.78, 1.0, Curves.easeOutCubic);
    return Opacity(
      opacity: v.clamp(0.0, 1.0),
      child: Transform.translate(
        offset: Offset(0, (1 - v) * 10),
        child: Text(
          'Your Earning Mentor',
          style: GoogleFonts.caveat(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            color: UiColors.sand,
          ),
        ),
      ),
    );
  }

  Widget _loader() {
    final fade = _p(0.75, 1.0);
    return Opacity(
      opacity: fade,
      child: Container(
        width: 120,
        height: 6,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
          boxShadow: UiShadows.card,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Align(
            alignment: Alignment(-1 + 2 * _loop.value, 0),
            child: FractionallySizedBox(
              widthFactor: 0.36,
              child: Container(color: UiColors.sand),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_blockingScreen != null) return _blockingScreen!;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // White status-bar icons on top of the slate sheet
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: UiColors.bg,
        body: LayoutBuilder(
          builder: (context, c) {
            final sheetH = c.maxHeight * 0.60;

            return AnimatedBuilder(
              animation: Listenable.merge([_intro, _loop]),
              builder: (context, _) {
                return Stack(
                  children: [
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: _sheet(c.maxWidth, sheetH),
                    ),
                    Positioned(
                      top: sheetH,
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _titleText(),
                          const SizedBox(height: 2),
                          _tagline(),
                        ],
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 40,
                      child: Center(child: _loader()),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

/// Slides a gradient horizontally: progress 0..1 moves it from fully left
/// of the box to fully right of it.
class _SlideGradient extends GradientTransform {
  final double progress;
  const _SlideGradient(this.progress);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(
        bounds.width * (progress * 2 - 1), 0, 0);
  }
}

/// Soft white rings that keep expanding and fading out behind the mascot.
class _RingsPainter extends CustomPainter {
  final double t; // 0..1 looping
  final double fade; // 0..1 intro fade-in

  _RingsPainter({required this.t, required this.fade});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);

    for (var i = 0; i < 3; i++) {
      final p = (t + i / 3) % 1.0;
      final radius = 96 + p * 170;
      final opacity = (1 - p) * 0.22 * fade;
      final ring = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = Colors.white.withValues(alpha: opacity);
      canvas.drawCircle(c, radius, ring);
    }
  }

  @override
  bool shouldRepaint(covariant _RingsPainter old) =>
      old.t != t || old.fade != fade;
}