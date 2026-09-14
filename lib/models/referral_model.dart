import 'package:cloud_firestore/cloud_firestore.dart';

class ReferralRecord {
  final String id;
  final String referrerUid;
  final String referredUid;
  final String referralCode;
  final bool completed; // true once referred user finishes 1 verified activity
  final DateTime? createdAt;

  ReferralRecord({
    required this.id,
    required this.referrerUid,
    required this.referredUid,
    required this.referralCode,
    required this.completed,
    required this.createdAt,
  });

  factory ReferralRecord.fromMap(String id, Map<String, dynamic> map) {
    return ReferralRecord(
      id: id,
      referrerUid: map['referrerUid'] ?? '',
      referredUid: map['referredUid'] ?? '',
      referralCode: map['referralCode'] ?? '',
      completed: map['completed'] ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}