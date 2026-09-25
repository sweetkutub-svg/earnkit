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
    required double amount,
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
