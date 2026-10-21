import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class LocationReportService {
  static const String _endpoint =
      'https://earnkit-backend.vercel.app/api/report-signal';
  static const String _key = 'last_location_report_ms';
  static bool _doneThisSession = false;

  /// Fire-and-forget, at most once per day. Never throws.
  static Future<void> reportOncePerDay() async {
    if (_doneThisSession) return;
    _doneThisSession = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final last = prefs.getInt(_key) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - last < 24 * 3600 * 1000) return;

      final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (idToken == null) return;

      final r = await http.post(
        Uri.parse(_endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({'type': 'LOCATION'}),
      );
      if (r.statusCode == 200) await prefs.setInt(_key, now);
    } catch (_) {}
  }
}