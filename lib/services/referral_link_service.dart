import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReferralLinkService {
  static const String _key = 'pending_referral_code';
  static final RegExp _clipboardPattern =
      RegExp(r'^EARNKIT_REF:([A-Z0-9]{4,12})$');

  static Future<void> savePending(String code) async {
    final cleaned = code.trim().toUpperCase();
    if (cleaned.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, cleaned);
  }

  static Future<String?> getPending() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_key);
    return (code == null || code.isEmpty) ? null : code;
  }

  static Future<void> clearPending() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  /// Fresh-install fallback: the invite page copies "EARNKIT_REF:CODE"
  /// to the clipboard when the user taps Download.
  static Future<String?> detectFromClipboard() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final match = _clipboardPattern.firstMatch(data?.text?.trim() ?? '');
      if (match == null) return null;
      await Clipboard.setData(const ClipboardData(text: ''));
      return match.group(1);
    } catch (_) {
      return null;
    }
  }
}