import 'package:cloud_firestore/cloud_firestore.dart';

enum WithdrawalStatus { pending, approved, paid, rejected }

class WithdrawalRequest {
  final String id;
  final String uid;
  final int amount;
  final String upiId;
  final WithdrawalStatus status;
  final DateTime? requestedAt;
  final String? gatewayTransactionId;

  WithdrawalRequest({
    required this.id,
    required this.uid,
    required this.amount,
    required this.upiId,
    required this.status,
    required this.requestedAt,
    this.gatewayTransactionId,
  });

  factory WithdrawalRequest.fromMap(String id, Map<String, dynamic> map) {
    return WithdrawalRequest(
      id: id,
      uid: map['uid'] ?? '',
      amount: (map['amount'] ?? 0) as int,
      upiId: map['upiId'] ?? '',
      status: _statusFromString(map['status'] ?? 'pending'),
      requestedAt: (map['requestedAt'] as Timestamp?)?.toDate(),
      gatewayTransactionId: map['gatewayTransactionId'],
    );
  }

  static WithdrawalStatus _statusFromString(String value) {
    switch (value) {
      case 'approved':
        return WithdrawalStatus.approved;
      case 'paid':
        return WithdrawalStatus.paid;
      case 'rejected':
        return WithdrawalStatus.rejected;
      default:
        return WithdrawalStatus.pending;
    }
  }
}