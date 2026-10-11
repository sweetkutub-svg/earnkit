import 'dart:async';
import 'dart:convert';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  // Google's official test rewarded ad unit. Safe to tap during development.
  static const String _testRewardedAdUnitId =
      'ca-app-pub-3940256099942544/5224354917';

  // Put your real rewarded ad unit ID here right before release.
  static const String _liveRewardedAdUnitId = 'REPLACE_WITH_REAL_AD_UNIT_ID';

  // Keep true until the app is live.
  static const bool _useTestAds = true;

  static String get _adUnitId =>
      _useTestAds ? _testRewardedAdUnitId : _liveRewardedAdUnitId;

  static const String _verifyAdEndpoint =
      'https://earnkit-backend.vercel.app/api/verify-ad';

  /// When no ad is available, should gate ads (task submit / withdrawal) block the user?
  static const bool blockGateWhenAdUnavailable = false;

  final _authService = AuthService();

  RewardedAd? _rewardedAd;
  bool _loading = false;

  bool get isAdReady => _rewardedAd != null;

  Future<bool> _load() {
    if (_rewardedAd != null) return Future.value(true);
    if (_loading) {
      // Wait for the load that is already running.
      return Future.doWhile(() async {
        await Future.delayed(const Duration(milliseconds: 200));
        return _loading;
      }).then((_) => _rewardedAd != null);
    }

    _loading = true;
    final completer = Completer<bool>();

    RewardedAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _loading = false;
          if (!completer.isCompleted) completer.complete(true);
        },
        onAdFailedToLoad: (error) {
          _rewardedAd = null;
          _loading = false;
          // ignore: avoid_print
          print('ADMOB load failed: ${error.code} | ${error.message}');
          if (!completer.isCompleted) completer.complete(false);
        },
      ),
    );

    return completer.future.timeout(
      const Duration(seconds: 20),
      onTimeout: () {
        _loading = false;
        return false;
      },
    );
  }

  void loadRewardedAd({
    required Function() onLoaded,
    required Function(String) onFailed,
  }) {
    _load().then((ok) {
      if (ok) {
        onLoaded();
      } else {
        onFailed('Ad failed to load');
      }
    });
  }

  /// "Watch Ad & Earn": credits points through the backend after the full ad.
  void showRewardedAd({
    required Function(int pointsCredited, bool bonusUnlocked, int bonusAmount)
        onEarnedReward,
    required Function(String error) onCreditFailed,
    required Function() onAdClosed,
  }) {
    final ad = _rewardedAd;
    if (ad == null) {
      onCreditFailed('Ad is not ready yet. Please try again in a moment.');
      onAdClosed();
      return;
    }
    _rewardedAd = null;

    bool earned = false;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) async {
        ad.dispose();
        if (earned) {
          await _callVerifyEndpoint(
            onSuccess: onEarnedReward,
            onFailed: onCreditFailed,
          );
        } else {
          onCreditFailed('Please watch the full ad to earn points.');
        }
        onAdClosed();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        onCreditFailed('Could not show the ad. Please try again.');
        onAdClosed();
      },
    );

    ad.show(onUserEarnedReward: (_, __) {
      earned = true;
    });
  }

  /// Gate ad (no points) before task submit / withdrawal. Returns true if the user may proceed.
  Future<bool> watchGateAd() async {
    final loaded = await _load();
    final ad = _rewardedAd;
    if (!loaded || ad == null) return !blockGateWhenAdUnavailable;
    _rewardedAd = null;

    final result = Completer<bool>();
    bool earned = false;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        if (!result.isCompleted) result.complete(earned);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        if (!result.isCompleted) {
          result.complete(!blockGateWhenAdUnavailable);
        }
      },
    );

    ad.show(onUserEarnedReward: (_, __) {
      earned = true;
    });

    final allowed = await result.future;
    unawaited(_load());
    return allowed;
  }

  Future<void> _callVerifyEndpoint({
    required Function(int pointsCredited, bool bonusUnlocked, int bonusAmount)
        onSuccess,
    required Function(String error) onFailed,
  }) async {
    final user = _authService.currentUser;
    if (user == null) {
      onFailed('Not logged in');
      return;
    }

    try {
      final idToken = await user.getIdToken();
      final response = await http.post(
        Uri.parse(_verifyAdEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({'uid': user.uid}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        onSuccess(
          (data['pointsCredited'] as num).toInt(),
          data['bonusUnlocked'] == true,
          ((data['bonusAmount'] ?? 0) as num).toInt(),
        );
      } else if (response.statusCode == 429) {
        if (data.containsKey('retryAfterSeconds')) {
          onFailed(
              'Please wait ${data['retryAfterSeconds']}s before watching another ad');
        } else if (data.containsKey('limit')) {
          onFailed('Daily ad limit reached (${data['limit']} ads/day)');
        } else {
          onFailed(data['error'] ?? 'Too many requests, please try again');
        }
      } else {
        onFailed(data['error'] ?? 'Failed to credit reward');
      }
    } catch (e) {
      onFailed('Network error: could not verify ad');
    }
  }
}