import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // Request permission for push notifications
    NotificationSettings settings = await _firebaseMessaging.requestPermission(alert: true, badge: true, sound: true);

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // Local Notification initialization setup
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInit = DarwinInitializationSettings();
      const initSettings = InitializationSettings(android: androidInit, iOS: iosInit);

      await _localNotifications.initialize(initSettings);

      // Listen for foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _showNotification(message);
      });
    }
  }

  Future<String?> getToken() async {
    return await _firebaseMessaging.getToken();
  }

  Future<void> _showNotification(RemoteMessage message) async {
    const androidDetails = AndroidNotificationDetails(
      'ridonova_channel',
      'Ride Updates',
      channelDescription: 'Notifications for ride status and captain arrival',
      importance: Importance.max,
      priority: Priority.high,
    );

    const notificationDetails = NotificationDetails(android: androidDetails, iOS: DarwinNotificationDetails());

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? 'Ride Update',
      message.notification?.body ?? '',
      notificationDetails,
    );
  }
}
