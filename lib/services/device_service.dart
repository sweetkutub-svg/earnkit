import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:safe_device/safe_device.dart';

class DeviceService {
  /// Returns true if this device is an emulator, rooted/jailbroken,
  /// or otherwise flagged as unsafe for ad-earning (Phase 16,
  /// 03_SECURITY.md Section 5). Blocks earning features only — not
  /// full app access.
  Future<bool> isDeviceFlagged() async {
    try {
      final isRealDevice = await SafeDevice.isRealDevice;
      final isJailBroken = await SafeDevice.isJailBroken;
      final isOnExternalStorage = await SafeDevice.isOnExternalStorage;
      return !isRealDevice || isJailBroken || isOnExternalStorage;
    } catch (_) {
      // If the check itself fails, don't block earning —
      // fail open rather than breaking the app for everyone.
      return false;
    }
  }
  Future<String> getDeviceId() async {
    if (!Platform.isAndroid) return 'unknown_platform';

    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
    // androidId is a per-app-install unique identifier on Android 8+.
    // Good enough for basic one-account-per-device fraud checks (roadmap
    // Phase 15 / 03_SECURITY.md Section 5). Not spoof-proof against a
    // determined attacker with root access — that's Phase 16's job.
    return androidInfo.id;
  }
}