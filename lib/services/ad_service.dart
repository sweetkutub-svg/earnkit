import 'dart:async';
import 'dart:convert';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';

class _Slot {
  final String liveId;
  RewardedAd? ad;
  bool loading = false;
  _Slot(this.liveId);
}

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  // Google's official test rewarded ad unit. Safe to tap during development.
  static const String _testRewardedAdUnitId =
      'ca-app-pub-3940256099942544/5224354917';

  // Debug builds use test ads, release builds use the real ad units.
  static const bool _useTestAds = !bool.fromEnvironment('dart.vm.product');

  final _Slot _rewardSlot = _Slot('ca-app-pub-3489289706205442/4083089856');
  final _Slot _gateSlot = _Slot('ca-app-pub-3489289706205442/1726188121');

  String _idFor(_Slot s) => _useTestAds ? _testRewardedAdUnitId : s.liveId;

  static const String _verifyAdEndpoint =
      'https://earnkit-backend.vercel.app/api/verify-ad';

  /// When no ad is available, should gate ads (task submit / withdrawal) block the user?
  static const bool blockGateWhenAdUnavailable = false;

  final _authService = AuthService();

  bool get isAdReady => _rewardSlot.ad != null;

  Future<bool> _load(_Slot slot) {
    if (slot.ad != null) return Future.value(true);
    if (slot.loading) {
      return Future.doWhile(() async {
        await Future.delayed(const Duration(milliseconds: 200));
        return slot.loading;
      }).then((_) => slot.ad != null);
    }

    slot.loading = true;
    final completer = Completer<bool>();

    RewardedAd.load(
      adUnitId: _idFor(slot),
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          slot.ad = ad;
          slot.loading = false;
          if (!completer.isCompleted) completer.complete(true);
        },
        onAdFailedToLoad: (error) {
          slot.ad = null;
          slot.loading = false;
          // ignore: avoid_print
          print('ADMOB load failed: ${error.code} | ${error.message}');
          if (!completer.isCompleted) completer.complete(false);
        },
      ),
    );

    return completer.future.timeout(
      const Duration(seconds: 20),
      onTimeout: () {
        slot.loading = false;
        return false;
      },
    );
  }

  /// Warm up the gate ad so withdraw / task submit feel instant.
  void preloadGateAd() {
    unawaited(_load(_gateSlot));
  }

  void loadRewardedAd({
    required Function() onLoaded,
    required Function(String) onFailed,
  }) {
    _load(_rewardSlot).then((ok) {
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
    final ad = _rewardSlot.ad;
    if (ad == null) {
      onCreditFailed('Ad is not ready yet. Please try again in a moment.');
      onAdClosed();
      return;
    }
    _rewardSlot.ad = null;

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
    final loaded = await _load(_gateSlot);
    final ad = _gateSlot.ad;
    if (!loaded || ad == null) return !blockGateWhenAdUnavailable;
    _gateSlot.ad = null;

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
    unawaited(_load(_gateSlot));
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