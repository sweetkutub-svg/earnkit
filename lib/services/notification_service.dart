import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // The system tray shows the notification automatically when the app is
  // backgrounded or terminated. The sound comes from the payments channel.
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();
  static bool _localReady = false;

  static const AndroidNotificationChannel _paymentsChannel =
      AndroidNotificationChannel(
    'payments_v1',
    'Payments',
    description: 'Withdrawal and payment alerts',
    importance: Importance.max,
    playSound: true,
    sound: RawResourceAndroidNotificationSound('payment_success'),
  );

  final _messaging = FirebaseMessaging.instance;
  final _firestore = FirebaseFirestore.instance;

  Future<void> init() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    await _initLocal();

    final token = await _messaging.getToken();
    await _saveToken(token);

    _messaging.onTokenRefresh.listen(_saveToken);
  }

  static Future<void> _initLocal() async {
    if (_localReady) return;
    await _local.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_paymentsChannel);
    _localReady = true;
  }

  /// Shows a payment notification with sound while the app is open.
  static Future<void> showPayment(RemoteMessage message) async {
    await _initLocal();
    await _local.show(
      id: message.hashCode,
      title: message.notification?.title ?? 'Payment received',
      body: message.notification?.body ?? '',
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _paymentsChannel.id,
          _paymentsChannel.name,
          channelDescription: _paymentsChannel.description,
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          sound: _paymentsChannel.sound,
        ),
      ),
    );
  }

  Future<void> _saveToken(String? token) async {
    if (token == null) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await _firestore.collection('users').doc(uid).update({
      'fcmToken': token,
    });
  }
}