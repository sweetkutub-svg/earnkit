import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/transaction_model.dart';
import '../models/withdrawal_model.dart';
import '../models/referral_model.dart';
import '../models/task_model.dart';
import '../models/task_submission_model.dart';

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

  // ---------- TASKS ----------

  Stream<List<AppTask>> streamActiveTasks() {
    return _db
        .collection('tasks')
        .where('active', isEqualTo: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => AppTask.fromMap(doc.id, doc.data()))
            .toList());
  }

  // ---------- TASK SUBMISSIONS (apply -> screenshot -> admin verify) ----------

  String _subId(String uid, String taskId) => '${uid}_$taskId';

  /// Apply (ya expire hone ke baad dobara apply). Purana doc overwrite hota hai.
  Future<void> applyToTask({required String uid, required AppTask task}) async {
    await _db.collection('task_submissions').doc(_subId(uid, task.id)).set({
      'uid': uid,
      'taskId': task.id,
      'taskTitle': task.title,
      'rewardPoints': task.rewardPoints,
      'status': 'applied',
      'appliedAt': FieldValue.serverTimestamp(),
      'expiresAt': Timestamp.fromDate(
          DateTime.now().add(Duration(hours: task.durationHours))),
      'screenshotUrl': '',
      'reviewNote': '',
    });
  }

  /// Screenshot upload hone ke baad: applied/rejected -> pending
  Future<void> submitScreenshot({
    required String uid,
    required String taskId,
    required String screenshotUrl,
  }) async {
    await _db.collection('task_submissions').doc(_subId(uid, taskId)).update({
      'status': 'pending',
      'screenshotUrl': screenshotUrl,
      'submittedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<TaskSubmission?> streamSubmission(String uid, String taskId) {
    return _db
        .collection('task_submissions')
        .doc(_subId(uid, taskId))
        .snapshots()
        .map((d) => d.exists ? TaskSubmission.fromMap(d.id, d.data()!) : null);
  }

  /// orderBy nahi hai (index ki zarurat nahi), sorting yahin Dart mein.
  Stream<List<TaskSubmission>> streamMySubmissions(String uid) {
    return _db
        .collection('task_submissions')
        .where('uid', isEqualTo: uid)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((doc) => TaskSubmission.fromMap(doc.id, doc.data()))
          .toList();
      list.sort((a, b) => b.sortTime.compareTo(a.sortTime));
      return list;
    });
  }
  
  // ---------- TASK PROGRESS ----------

  Stream<Map<String, int>> streamCompletedCounts(String uid) {
    return _db
        .collection('task_progress')
        .where('uid', isEqualTo: uid)
        .snapshots()
        .map((snap) => {
              for (final d in snap.docs)
                (d.data()['taskId'] as String? ?? ''):
                    ((d.data()['completedCount'] ?? 0) as num).toInt(),
            });
  }
}
