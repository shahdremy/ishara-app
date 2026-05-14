import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
  FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const androidSettings =
    AndroidInitializationSettings('@mipmap/app_icon');

    const initSettings =
    InitializationSettings(android: androidSettings);

    await _notifications.initialize(initSettings);

    // ✅ طلب إذن الإشعارات (Android 13+)
    final androidPlugin =
    _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.requestNotificationsPermission();
  }

  static Future<void> show({
    required int id,
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'ishara_channel',
      'Ishara Notifications',
      channelDescription: 'إشعارات تطبيق إشارة',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/app_icon',
    );

    const details = NotificationDetails(android: androidDetails);

    await _notifications.show(id, title, body, details);
  }
}
