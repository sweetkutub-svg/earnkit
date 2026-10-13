import 'dart:io';
import 'package:android_id/android_id.dart';
import 'package:safe_device/safe_device.dart';

class DeviceService {
  /// Returns true if this device is an emulator, rooted/jailbroken,
  /// or otherwise flagged as unsafe for ad-earning. Blocks earning
  /// features only, not full app access.
  Future<bool> isDeviceFlagged() async {
    try {
      final isRealDevice = await SafeDevice.isRealDevice;
      final isJailBroken = await SafeDevice.isJailBroken;
      final isOnExternalStorage = await SafeDevice.isOnExternalStorage;
      return !isRealDevice || isJailBroken || isOnExternalStorage;
    } catch (_) {
      // If the check itself fails, don't block earning:
      // fail open rather than breaking the app for everyone.
      return false;
    }
  }

  /// A stable per-device identifier (Settings.Secure.ANDROID_ID).
  /// It stays the same across app reinstalls and updates. It changes only on
  /// a factory reset or when the app's signing key changes.
  ///
  /// Returns 'unknown_platform' when no ID is available, and the callers
  /// treat that as "do not block", so we never lock everyone out by mistake.
  Future<String> getDeviceId() async {
    if (!Platform.isAndroid) return 'unknown_platform';

    try {
      final id = await const AndroidId().getId();
      if (id == null || id.trim().isEmpty) return 'unknown_platform';
      return id.trim();
    } catch (_) {
      return 'unknown_platform';
    }
  }
}