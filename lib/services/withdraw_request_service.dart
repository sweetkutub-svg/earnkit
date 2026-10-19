import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class WithdrawRequestService {
  static const _url = 'https://earnkit-backend.vercel.app/api/submit-withdrawal';

  /// Returns {'success': true, ...} or {'success': false, 'error': '...'}.
  Future<Map<String, dynamic>> submit({
    required String upiId,
    required String bankName,
    required String holderName,
    required int points,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return {'success': false, 'error': 'Please log in again.'};
      }
      final token = await user.getIdToken();
      final res = await http
          .post(
            Uri.parse(_url),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'upiId': upiId,
              'bankName': bankName,
              'holderName': holderName,
              'points': points,
            }),
          )
          .timeout(const Duration(seconds: 25));

      Map<String, dynamic> data = {};
      try {
        data = jsonDecode(res.body) as Map<String, dynamic>;
      } catch (_) {}

      if (res.statusCode == 200 && data['success'] == true) {
        return {'success': true, ...data};
      }
      return {
        'success': false,
        'error': (data['error'] ?? 'Request failed (${res.statusCode})')
            .toString(),
      };
    } catch (_) {
      return {
        'success': false,
        'error': 'Network error. Please check your connection and try again.',
      };
    }
  }
}