import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_spacing.dart';

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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
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
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                child: Align(
                  alignment: Alignment.topRight,
                  child: isLastPage
                      ? const SizedBox(height: 40)
                      : TextButton(
                          onPressed: _goToLogin,
                          child: Text(
                            'Skip',
                            style: AppTextStyles.bodyText
                                .copyWith(color: AppColors.gray600),
                          ),
                        ),
                ),
              ),
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
                        final mediaSize =
                            (constraints.maxHeight * 0.48).clamp(160.0, 300.0);
                        return SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xl),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                                minHeight: constraints.maxHeight),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _SlideMedia(
                                  key: ValueKey('$index-${slide.mediaUrl}'),
                                  slide: slide,
                                  size: mediaSize,
                                ),
                                const SizedBox(height: AppSpacing.xl),
                                Text(
                                  slide.title,
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.h1ScreenTitle,
                                ),
                                const SizedBox(height: AppSpacing.md),
                                Text(
                                  slide.description,
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.bodyText,
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
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _slides.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? AppColors.emerald
                          : AppColors.gray200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
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
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _goToLogin,
                              child: const Text('Skip'),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _nextPage,
                              child: const Text('Next'),
                            ),
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shows the slide's image or a looping, muted, auto-playing video.
/// While the media loads it shows a neutral box with a spinner; the icon box
/// is only used when the slide has no media or the media fails to load.
class _SlideMedia extends StatefulWidget {
  final _Slide slide;
  final double size;
  const _SlideMedia({super.key, required this.slide, required this.size});

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

  Widget _iconBox() {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Icon(widget.slide.icon,
          size: widget.size * 0.4, color: AppColors.white),
    );
  }

  Widget _loadingBox() {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: AppColors.gray100,
        borderRadius: BorderRadius.circular(24),
      ),
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

    Widget child;
    if (slide.mediaType == 'image') {
      child = Image.network(
        slide.mediaUrl,
        width: widget.size,
        height: widget.size,
        fit: BoxFit.cover,
        loadingBuilder: (context, img, progress) =>
            progress == null ? img : _loadingBox(),
        errorBuilder: (_, __, ___) => _iconBox(),
      );
    } else if (_videoReady && _video != null) {
      final v = _video!;
      child = SizedBox(
        width: widget.size,
        height: widget.size,
        child: FittedBox(
          fit: BoxFit.cover,
          clipBehavior: Clip.hardEdge,
          child: SizedBox(
            width: v.value.size.width,
            height: v.value.size.height,
            child: VideoPlayer(v),
          ),
        ),
      );
    } else {
      return _loadingBox();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: child,
    );
  }
}