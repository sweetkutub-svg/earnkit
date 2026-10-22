import 'package:google_mobile_ads/google_mobile_ads.dart';

class InterstitialService {
  static final InterstitialService _instance = InterstitialService._internal();
  factory InterstitialService() => _instance;
  InterstitialService._internal();

  static const String _testId = 'ca-app-pub-3940256099942544/1033173712';
  static const String _liveId = 'ca-app-pub-3489289706205442/5892488832';
  static const bool _useTestAds = !bool.fromEnvironment('dart.vm.product');
  static String get _adUnitId =>
      (_useTestAds || _liveId.startsWith('REPLACE')) ? _testId : _liveId;

  /// Minimum gap between two interstitials.
  static const Duration gap = Duration(minutes: 5);

  InterstitialAd? _ad;
  bool _loading = false;
  bool _showing = false;
  DateTime _lastShown = DateTime.now(); // first ad only after a full gap

  void preload() {
    if (_ad != null || _loading) return;
    _loading = true;
    InterstitialAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _ad = ad;
          _loading = false;
        },
        onAdFailedToLoad: (error) {
          _ad = null;
          _loading = false;
        },
      ),
    );
  }

  /// Call at a natural switch point (tab change / screen change).
  /// Shows an ad only if 5 minutes have passed since the last one.
  void maybeShowOnSwitch() {
    if (_showing) return;
    if (DateTime.now().difference(_lastShown) < gap) return;
    final ad = _ad;
    if (ad == null) {
      preload();
      return;
    }
    _ad = null;
    _showing = true;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _showing = false;
        _lastShown = DateTime.now();
        preload();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _showing = false;
        preload();
      },
    );
    ad.show();
  }
}