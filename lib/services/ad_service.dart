import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/auth_service.dart';

class AdService {
  static const String _testRewardedAdUnitId =
      'ca-app-pub-3940256099942544/5224354917';

  // Phase 7 backend endpoint (Vercel)
  static const String _verifyAdEndpoint =
      'https://earnkit-backend.vercel.app/api/verify-ad';

  RewardedAd? _rewardedAd;
  final _authService = AuthService();

  void loadRewardedAd({
    required Function() onLoaded,
    required Function(String) onFailed,
  }) {
    RewardedAd.load(
      adUnitId: _testRewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          onLoaded();
        },
        onAdFailedToLoad: (error) {
          _rewardedAd = null;
          onFailed(error.message);
        },
      ),
    );
  }

  bool get isAdReady => _rewardedAd != null;

  void showRewardedAd({
    required Function(int pointsCredited, bool bonusUnlocked, int bonusAmount)
        onEarnedReward,
    required Function(String error) onCreditFailed,
    required Function() onAdClosed,
  }) {
    if (_rewardedAd == null) return;

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        onAdClosed();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _rewardedAd = null;
        onAdClosed();
      },
    );

    _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) async {
        await _callVerifyEndpoint(
          onSuccess: onEarnedReward,
          onFailed: onCreditFailed,
        );
      },
    );
  }

  Future<void> _callVerifyEndpoint({
    required Function(int pointsCredited, bool bonusUnlocked, int bonusAmount)
        onSuccess,
    required Function(String error) onFailed,
  }) async {
    final uid = _authService.currentUser?.uid;
    if (uid == null) {
      onFailed('Not logged in');
      return;
    }

    try {
      final response = await http.post(
        Uri.parse(_verifyAdEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'uid': uid}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        onSuccess(
          data['pointsCredited'] as int,
          data['bonusUnlocked'] == true,
          (data['bonusAmount'] ?? 0) as int,
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
      onFailed('Network error — could not verify ad');
    }
  }
}