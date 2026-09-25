import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

class DeviceService {
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