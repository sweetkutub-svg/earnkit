import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import '../theme/ui_colors.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _Slide {
  final String title;
  final String description;
  final String mediaType; // 'none' | 'image' | 'video'
  final String mediaUrl;
  final IconData icon;

  const _Slide({
    required this.title,
    required this.description,
    required this.icon,
    this.mediaType = 'none',
    this.mediaUrl = '',
  });
}

const List<IconData> _fallbackIcons = [
  Icons.play_circle_outline,
  Icons.groups_outlined,
  Icons.account_balance_wallet_outlined,
  Icons.stars_outlined,
];

const List<Color> _slideColors = [
  UiColors.mint,
  UiColors.lilac,
  UiColors.peach,
];

const List<_Slide> _defaultSlides = [
  _Slide(
    title: 'Earn by Watching Ads',
    description:
        'Watch premium video ads from world-class brands and earn rewards directly in your wallet.',
    icon: Icons.play_circle_outline,
  ),
  _Slide(
    title: 'Invite & Earn Together',
    description:
        'Share the flow. Get up to ₹100 for every friend who signs up and starts earning. No limits.',
    icon: Icons.groups_outlined,
  ),
  _Slide(
    title: 'Instant UPI Withdrawal',
    description:
        'Transfer your earned balance directly to any bank account via UPI. Instant, secure, and hassle-free.',
    icon: Icons.account_balance_wallet_outlined,
  ),
];

/// Asks Cloudinary for a small, widely-playable version of the media:
/// images as 700px WebP, videos as 540px H.264 MP4 without audio.
String _optimizeUrl(String url, String type) {
  if (!url.contains('res.cloudinary.com')) return url;
  if (!RegExp(r'/upload/v\d+/').hasMatch(url)) return url; // already transformed
  if (type == 'video') {
    var out = url.replaceFirst(
        '/upload/', '/upload/f_mp4,vc_h264,ac_none,w_540,q_auto/');
    out = out.replaceFirst(RegExp(r'\.[A-Za-z0-9]+$'), '');
    return '$out.mp4';
  }
  return url.replaceFirst('/upload/', '/upload/f_webp,q_auto,w_700/');
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  List<_Slide> _slides = _defaultSlides;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSlides();
  }

  Future<void> _loadSlides() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('app_config')
          .doc('onboarding')
          .get()
          .timeout(const Duration(seconds: 4));
      final raw = snap.data()?['slides'];
      if (raw is List) {
        final parsed = <_Slide>[];
        for (final item in raw) {
          if (item is! Map) continue;
          final title = (item['title'] ?? '').toString().trim();
          if (title.isEmpty) continue;
          final desc = (item['description'] ?? '').toString().trim();
          final type = (item['mediaType'] ?? 'none').toString();
          final url = (item['mediaUrl'] ?? '').toString().trim();
          final urlOk = Uri.tryParse(url)?.scheme == 'https';
          final useMedia = urlOk && (type == 'image' || type == 'video');
          parsed.add(_Slide(
            title: title,
            description: desc,
            icon: _fallbackIcons[parsed.length % _fallbackIcons.length],
            mediaType: useMedia ? type : 'none',
            mediaUrl: useMedia ? _optimizeUrl(url, type) : '',
          ));
        }
        if (parsed.isNotEmpty) _slides = parsed;
      }
    } catch (_) {
      // Keep the built-in slides if the config can't be loaded.
    }

    await _precacheImages();

    if (!mounted) return;
    setState(() => _loading = false);
  }

  /// Wait (briefly) for the first slide's image, and warm up the rest in the
  /// background, so slides don't pop in after the screen is shown.
  Future<void> _precacheImages() async {
    if (!mounted) return;
    for (var i = 0; i < _slides.length; i++) {
      final s = _slides[i];
      if (s.mediaType != 'image') continue;
      final future =
          precacheImage(NetworkImage(s.mediaUrl), context).catchError((_) {});
      if (i == 0) {
        await future.timeout(const Duration(seconds: 6), onTimeout: () {});
      } else {
        unawaited(future);
      }
    }
  }

  void _goToLogin() {
    context.go('/login');
  }

  void _nextPage() {
    if (_currentPage == _slides.length - 1) {
      _goToLogin();
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Widget _skipPill() {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      elevation: 3,
      shadowColor: Colors.black.withValues(alpha: 0.2),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: _goToLogin,
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 18, vertical: 9),
          child: Text('Skip',
              style: TextStyle(
                  fontSize: 13.5,
                  color: UiColors.muted,
                  fontWeight: FontWeight.w800)),
        ),
      ),
    );
  }

  Widget _dots() {
    return Row(
      children: List.generate(
        _slides.length,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.only(right: 6),
          width: _currentPage == index ? 28 : 9,
          height: 9,
          decoration: BoxDecoration(
            color: _currentPage == index ? UiColors.sand : UiColors.disabled,
            borderRadius: BorderRadius.circular(5),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: UiColors.bg,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isLastPage = _currentPage == _slides.length - 1;

    return PopScope(
      // On the first slide the back button exits the app normally.
      // On later slides it goes back one slide instead.
      canPop: _currentPage == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _previousPage();
      },
      child: Scaffold(
        backgroundColor: UiColors.bg,
        body: SafeArea(
          child: Column(
            children: [
              // Top bar
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 12, 22, 0),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text('Earnkit',
                          style: TextStyle(
                              fontSize: 24,
                              color: UiColors.ink,
                              fontWeight: FontWeight.w800)),
                    ),
                    if (isLastPage) const SizedBox(height: 38) else _skipPill(),
                  ],
                ),
              ),

              // Slides
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _slides.length,
                  onPageChanged: (index) {
                    setState(() => _currentPage = index);
                  },
                  itemBuilder: (context, index) {
                    final slide = _slides[index];
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final mediaHeight =
                            (constraints.maxHeight * 0.52).clamp(190.0, 360.0);
                        return SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 22),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                                minHeight: constraints.maxHeight),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _SlideMedia(
                                  key: ValueKey('$index-${slide.mediaUrl}'),
                                  slide: slide,
                                  height: mediaHeight,
                                  color: _slideColors[
                                      index % _slideColors.length],
                                ),
                                const SizedBox(height: 28),
                                Text(
                                  slide.title,
                                  style: const TextStyle(
                                      fontSize: 30,
                                      height: 1.15,
                                      color: UiColors.ink,
                                      fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  slide.description,
                                  style: const TextStyle(
                                      fontSize: 15,
                                      height: 1.5,
                                      color: UiColors.muted,
                                      fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              // Bottom controls
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
                child: isLastPage
                    ? SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _goToLogin,
                          child: const Text('Get Started'),
                        ),
                      )
                    : Row(
                        children: [
                          Expanded(child: _dots()),
                          Material(
                            color: UiColors.sand,
                            borderRadius: BorderRadius.circular(40),
                            elevation: 5,
                            shadowColor: Colors.black.withValues(alpha: 0.3),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(40),
                              onTap: _nextPage,
                              child: const Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 26, vertical: 15),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('Next',
                                        style: TextStyle(
                                            fontSize: 15,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w800)),
                                    SizedBox(width: 8),
                                    Icon(Icons.arrow_forward_rounded,
                                        color: Colors.white, size: 20),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shows the slide's image or a looping, muted, auto-playing video inside a
/// rounded card. While the media loads it shows a neutral box with a spinner;
/// the coloured icon card is only used when the slide has no media or the
/// media fails to load.
class _SlideMedia extends StatefulWidget {
  final _Slide slide;
  final double height;
  final Color color;
  const _SlideMedia({
    super.key,
    required this.slide,
    required this.height,
    required this.color,
  });

  @override
  State<_SlideMedia> createState() => _SlideMediaState();
}

class _SlideMediaState extends State<_SlideMedia> {
  VideoPlayerController? _video;
  bool _videoReady = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    if (widget.slide.mediaType == 'video') _initVideo();
  }

  Future<void> _initVideo() async {
    final controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.slide.mediaUrl),
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );
    _video = controller;
    try {
      await controller.initialize().timeout(const Duration(seconds: 15));
      await controller.setLooping(true);
      await controller.setVolume(0);
      await controller.play();
      if (mounted) setState(() => _videoReady = true);
    } catch (e) {
      debugPrint('ONBOARDING video failed: $e');
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _video?.dispose();
    super.dispose();
  }

  Widget _card({required Widget child, Color? color}) {
    return Container(
      width: double.infinity,
      height: widget.height,
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: UiShadows.card,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: child,
      ),
    );
  }

  Widget _iconBox() {
    final size = (widget.height * 0.42).clamp(80.0, 150.0);
    return _card(
      color: widget.color,
      child: Center(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: UiShadows.card,
          ),
          child: Icon(widget.slide.icon,
              size: size * 0.5, color: UiColors.sand),
        ),
      ),
    );
  }

  Widget _loadingBox() {
    return _card(
      child: const Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final slide = widget.slide;

    if (slide.mediaType == 'none' || _failed) return _iconBox();

    if (slide.mediaType == 'image') {
      return _card(
        child: Image.network(
          slide.mediaUrl,
          width: double.infinity,
          height: widget.height,
          fit: BoxFit.cover,
          loadingBuilder: (context, img, progress) => progress == null
              ? img
              : const Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                ),
          errorBuilder: (_, __, ___) => Container(
            color: widget.color,
            child: Center(
              child: Icon(slide.icon, size: 64, color: UiColors.sand),
            ),
          ),
        ),
      );
    }

    if (_videoReady && _video != null) {
      final v = _video!;
      return _card(
        child: SizedBox.expand(
          child: FittedBox(
            fit: BoxFit.cover,
            clipBehavior: Clip.hardEdge,
            child: SizedBox(
              width: v.value.size.width,
              height: v.value.size.height,
              child: VideoPlayer(v),
            ),
          ),
        ),
      );
    }

    return _loadingBox();
  }
}