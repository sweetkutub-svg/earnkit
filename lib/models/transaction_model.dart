import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionType { adWatched, taskCompleted, referralBonus, withdrawal }

class AppTransaction {
  final String id;
  final String uid;
  final TransactionType type;
  final int amount; // in EarnGrow Points, always server-set
  final String source;
  final DateTime? timestamp;

  AppTransaction({
    required this.id,
    required this.uid,
    required this.type,
    required this.amount,
    required this.source,
    required this.timestamp,
  });

  factory AppTransaction.fromMap(String id, Map<String, dynamic> map) {
    return AppTransaction(
      id: id,
      uid: map['uid'] ?? '',
      type: _typeFromString(map['type'] ?? ''),
      amount: (map['amount'] ?? 0) as int,
      source: map['source'] ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate(),
    );
  }

  static TransactionType _typeFromString(String value) {
    switch (value) {
      case 'ad_watched':
        return TransactionType.adWatched;
      case 'task_completed':
        return TransactionType.taskCompleted;
      case 'referral_bonus':
        return TransactionType.referralBonus;
      case 'withdrawal':
        return TransactionType.withdrawal;
      default:
        return TransactionType.adWatched;
    }
  }
}