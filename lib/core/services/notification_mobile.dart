// notification_mobile.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationAdapter {
  static final _notifications = FlutterLocalNotificationsPlugin();

  static Future<void> initialize(Function onStop) async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();

    // The mobile compiler knows how to handle these arguments
    await _notifications.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: (_) => onStop(),
    );
  }
}
