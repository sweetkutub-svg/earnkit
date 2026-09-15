import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';

class AdService {
  // Google's OFFICIAL public test ad unit ID for Rewarded ads (Android).
  // NEVER replace this with a real ad unit ID until Phase 20.
  static const String _testRewardedAdUnitId =
      'ca-app-pub-3940256099942544/5224354917';

  RewardedAd? _rewardedAd;
  final _authService = AuthService();
  final _firestoreService = FirestoreService();

  void loadRewardedAd({required Function() onLoaded, required Function(String) onFailed}) {
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
    required Function() onEarnedReward,
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
        // Phase 6 rule (per 03_SECURITY.md): DO NOT credit wallet here.
        // Only log the "ad watched" event. Real crediting happens in
        // Phase 7 via server-side AdMob SSV + Cloud Function.
        await _logAdWatchedEvent();
        onEarnedReward();
      },
    );
  }

  Future<void> _logAdWatchedEvent() async {
    final uid = _authService.currentUser?.uid;
    if (uid == null) return;
    // Log-only — no wallet credit. Uses the transactions collection
    // with a special 'source' tag so Phase 7 can identify+reconcile these.
    await _firestoreService.logAdWatchedEventOnly(uid);
  }
}