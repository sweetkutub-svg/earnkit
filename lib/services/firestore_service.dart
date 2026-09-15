import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/transaction_model.dart';
import '../models/withdrawal_model.dart';
import '../models/referral_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ---------- USERS ----------

  Future<AppUser?> getUserData(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return AppUser.fromMap(doc.data()!);
  }

  Stream<AppUser?> streamUserData(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return AppUser.fromMap(doc.data()!);
    });
  }

  // NOTE (see SECURITY_NOTES.md): this direct client-side wallet update is a
  // temporary Phase 4 scaffold for manual testing only. From Phase 7 onward,
  // wallet credits MUST go through a server-verified Cloud Function — this
  // method will be removed/blocked by Firestore rules at that point.
  Future<void> updateWallet({
    required String uid,
    required int amountDelta,
    required TransactionType type,
    required String source,
  }) async {
    final userRef = _db.collection('users').doc(uid);
    final txRef = _db.collection('transactions').doc();

    await _db.runTransaction((transaction) async {
      final userSnap = await transaction.get(userRef);
      final currentBalance = (userSnap.data()?['walletBalance'] ?? 0) as int;

      transaction.update(userRef, {
        'walletBalance': currentBalance + amountDelta,
      });

      transaction.set(txRef, {
        'uid': uid,
        'type': _typeToString(type),
        'amount': amountDelta,
        'source': source,
        'timestamp': FieldValue.serverTimestamp(),
      });
    });
  }

  String _typeToString(TransactionType type) {
    switch (type) {
      case TransactionType.adWatched:
        return 'ad_watched';
      case TransactionType.taskCompleted:
        return 'task_completed';
      case TransactionType.referralBonus:
        return 'referral_bonus';
      case TransactionType.withdrawal:
        return 'withdrawal';
    }
  }

  // ---------- PHASE 6: AD EVENT LOGGING (test-mode only, no wallet credit) ----------

  Future<void> logAdWatchedEventOnly(String uid) async {
    await _db.collection('transactions').add({
      'uid': uid,
      'type': 'ad_watched',
      'amount': 0, // 0 = not credited yet; Phase 7 SSV will credit via Cloud Function
      'source': 'TEST_AD_EVENT_LOG_ONLY_PHASE6',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // ---------- TRANSACTIONS ----------

  Stream<List<AppTransaction>> streamTransactions(String uid) {
    return _db
        .collection('transactions')
        .where('uid', isEqualTo: uid)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => AppTransaction.fromMap(doc.id, doc.data()))
            .toList());
  }

  // ---------- WITHDRAWALS ----------

  Future<void> createWithdrawalRequest({
    required String uid,
    required int amount,
    required String upiId,
  }) async {
    await _db.collection('withdrawals').add({
      'uid': uid,
      'amount': amount,
      'upiId': upiId,
      'status': 'pending',
      'requestedAt': FieldValue.serverTimestamp(),
      'gatewayTransactionId': null,
    });
  }

  Stream<List<WithdrawalRequest>> streamWithdrawals(String uid) {
    return _db
        .collection('withdrawals')
        .where('uid', isEqualTo: uid)
        .orderBy('requestedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => WithdrawalRequest.fromMap(doc.id, doc.data()))
            .toList());
  }

  // ---------- REFERRALS ----------

  Future<void> createReferralRecord({
    required String referrerUid,
    required String referredUid,
    required String referralCode,
  }) async {
    await _db.collection('referrals').add({
      'referrerUid': referrerUid,
      'referredUid': referredUid,
      'referralCode': referralCode,
      'completed': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<ReferralRecord>> streamReferralsByReferrer(String referrerUid) {
    return _db
        .collection('referrals')
        .where('referrerUid', isEqualTo: referrerUid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => ReferralRecord.fromMap(doc.id, doc.data()))
            .toList());
  }
}
