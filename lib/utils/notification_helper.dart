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

  /// Silent startup setup — channel, plugin init, foreground listener. Does NOT
  /// prompt for permission (that's [requestPermission], called later so the OS
  /// dialog doesn't slam the user the instant they open the app). Safe to call
  /// at launch.
  static Future<void> init() async {
    // Android channel
    await _localNotif
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    // Don't auto-request the iOS permission during init — we ask explicitly in
    // [requestPermission] once the user has settled into the app.
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotif.initialize(initSettings);

    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    _listenForeground();
  }

  /// Prompts for notification permission (Android 13+ / iOS). Call this AFTER
  /// the user has reached the app and had a moment to look around — never on the
  /// cold-start path — so the OS dialog feels contextual rather than an
  /// immediate interruption. Safe to call more than once: the OS shows the
  /// dialog only the first time and returns the existing decision after.
  static Future<void> requestPermission() async {
    try {
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (e) {
      debugPrint('requestPermission failed: $e');
    }
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
