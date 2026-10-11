import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class FraudReportService {
  static const String _endpoint =
      'https://earnkit-backend.vercel.app/api/report-signal';
  static final Set<String> _reportedThisSession = {};

  /// Fire-and-forget. Never throws, fraud reporting must not break the app.
  static Future<void> report(String type, {String? deviceId}) async {
    try {
      final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (idToken == null) return;
      await http.post(
        Uri.parse(_endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({'type': type, 'deviceId': deviceId}),
      );
    } catch (_) {}
  }

  static Future<void> reportOncePerSession(String type,
      {String? deviceId}) async {
    if (!_reportedThisSession.add(type)) return;
    await report(type, deviceId: deviceId);
  }
}