import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppRemoteConfig {
  final bool maintenanceMode;
  final String maintenanceMessage;
  final String minRequiredVersion;
  final String updateMessage;

  AppRemoteConfig({
    required this.maintenanceMode,
    required this.maintenanceMessage,
    required this.minRequiredVersion,
    required this.updateMessage,
  });

  factory AppRemoteConfig.fromMap(Map<String, dynamic> map) {
    return AppRemoteConfig(
      maintenanceMode: map['maintenanceMode'] ?? false,
      maintenanceMessage: map['maintenanceMessage'] ??
          'Earnkit is under maintenance. Please check back soon.',
      minRequiredVersion: map['minRequiredVersion'] ?? '1.0.0',
      updateMessage: map['updateMessage'] ??
          'A new version of Earnkit is available. Please update to continue.',
    );
  }
}

class RemoteConfigService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<AppRemoteConfig> fetchConfig() async {
    try {
      final doc = await _db.collection('app_config').doc('general').get();
      if (!doc.exists) {
        return AppRemoteConfig.fromMap({});
      }
      return AppRemoteConfig.fromMap(doc.data()!);
    } catch (e) {
      return AppRemoteConfig.fromMap({});
    }
  }

  Future<bool> isUpdateRequired(String minRequiredVersion) async {
    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.version;
    return _compareVersions(currentVersion, minRequiredVersion) < 0;
  }

  int _compareVersions(String a, String b) {
    final aParts = a.split('.').map(int.parse).toList();
    final bParts = b.split('.').map(int.parse).toList();
    for (int i = 0; i < 3; i++) {
      final aVal = i < aParts.length ? aParts[i] : 0;
      final bVal = i < bParts.length ? bParts[i] : 0;
      if (aVal != bVal) return aVal.compareTo(bVal);
    }
    return 0;
  }
}