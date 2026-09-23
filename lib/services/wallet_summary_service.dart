import 'dart:convert';
import 'package:http/http.dart' as http;

class WalletSummary {
  final int points;
  final int unlockedBonus;
  final int minWithdrawalPoints;
  final bool isEligible;
  final double convertedRupees;
  final double totalWithdrawable;
  final int pointsNeeded;

  WalletSummary({
    required this.points,
    required this.unlockedBonus,
    required this.minWithdrawalPoints,
    required this.isEligible,
    required this.convertedRupees,
    required this.totalWithdrawable,
    required this.pointsNeeded,
  });

  factory WalletSummary.fromJson(Map<String, dynamic> json) {
    return WalletSummary(
      points: json['points'] ?? 0,
      unlockedBonus: json['unlockedBonus'] ?? 0,
      minWithdrawalPoints: json['minWithdrawalPoints'] ?? 500,
      isEligible: json['isEligible'] ?? false,
      convertedRupees: (json['convertedRupees'] ?? 0).toDouble(),
      totalWithdrawable: (json['totalWithdrawable'] ?? 0).toDouble(),
      pointsNeeded: json['pointsNeeded'] ?? 0,
    );
  }
}

class WalletSummaryService {
  static const String _baseUrl = 'https://earnkit-backend.vercel.app';

  Future<WalletSummary?> fetchSummary(String uid) async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/api/get-wallet-summary?uid=$uid'));
      if (response.statusCode == 200) {
        return WalletSummary.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> submitWithdrawal({
    required String uid,
    required String upiId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/submit-withdrawal'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'uid': uid, 'upiId': upiId}),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, ...data};
      }
      return {'success': false, 'error': data['error'] ?? 'Request failed'};
    } catch (e) {
      return {'success': false, 'error': 'Network error'};
    }
  }
}