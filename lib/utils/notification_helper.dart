import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Handles device-side push setup: permissions, the Android notification
/// channel, and showing a heads-up banner when a push arrives while the app is
/// in the foreground (FCM does not do this automatically on Android).
class NotificationHelper {
  static final FlutterLocalNotificationsPlugin _localNotif =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'Used for important notifications',
    importance: Importance.high,
  );

  static Future<void> init() async {
    // Android channel
    await _localNotif
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotif.initialize(initSettings);

    // Permission (Android 13+ / iOS)
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    _listenForeground();
  }

  /// Saves this device's FCM token under `users/<uid>/fcmToken` (read by the
  /// sendBroadcast Cloud Function) and keeps it fresh on refresh. Call after
  /// the user's profile node exists.
  static Future<void> saveToken(String uid) async {
    final userRef = FirebaseDatabase.instance.ref('users/$uid');
    try {
      final snap = await userRef.get();
      if (!snap.exists) return; // don't create a partial user node

      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        await userRef.update({'fcmToken': token});
      }

      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        userRef.update({'fcmToken': newToken});
      });
    } catch (e) {
      debugPrint('saveToken failed: $e');
    }
  }

  // Foreground: manually show a banner (FCM won't on Android when app is open).
  static void _listenForeground() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification == null) return;

      _localNotif.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentSound: true,
            presentBadge: true,
          ),
        ),
      );
    });
  }
}
