import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class BannerAdWidget extends StatefulWidget {
  final bool labeled;
  const BannerAdWidget({super.key, this.labeled = false});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  // Google's official test banner unit. Safe to tap during development.
  static const String _testBannerId = 'ca-app-pub-3940256099942544/6300978111';

  // Put your real banner ad unit ID here right before release.
  static const String _liveBannerId = 'REPLACE_WITH_REAL_BANNER_UNIT_ID';

  static const bool _useTestAds = true;

  BannerAd? _ad;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _ad = BannerAd(
      adUnitId: _useTestAds ? _testBannerId : _liveBannerId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          // ignore: avoid_print
          print('ADMOB banner failed: ${error.code} | ${error.message}');
          if (mounted) setState(() => _loaded = false);
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _ad == null) return const SizedBox.shrink();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.labeled)
          const Padding(
            padding: EdgeInsets.only(bottom: 4),
            child: Text(
              'Advertisement',
              style: TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ),
        SizedBox(
          width: _ad!.size.width.toDouble(),
          height: _ad!.size.height.toDouble(),
          child: AdWidget(ad: _ad!),
        ),
      ],
    );
  }
}