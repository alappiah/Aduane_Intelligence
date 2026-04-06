import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    try {
      tz.initializeTimeZones();

      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@drawable/ic_notification');

      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true,
          );

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      // 🌟 Move initialize TO THE TOP so the plugin is ready
      // before we ask for permissions.
      await _notificationsPlugin.initialize(initSettings);

      final androidImplementation =
          _notificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();

      if (androidImplementation != null) {
        await androidImplementation.requestNotificationsPermission();
      }
    } catch (e) {
      // If the icon is missing, the app will still open,
      // and you'll see this error in your logs instead of a hang!
      debugPrint("⚠️ Notification Init Failed: $e");
    }
  }

  // ==========================================
  // 1. INSTANT NOTIFICATIONS (Goals, Badges, Sedentary)
  // ==========================================
  static Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const NotificationDetails details = NotificationDetails(
      android: AndroidNotificationDetails(
        'aduane_channel',
        'Aduane Alerts',
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
    await _notificationsPlugin.show(id, title, body, details);
  }

  // ==========================================
  // 2. SCHEDULED DAILY NOTIFICATIONS (Morning Brief, Meals, Streak)
  // ==========================================
  static Future<void> scheduleDaily({
    required int id,
    required String title,
    required String body,
    required int hour,
  }) async {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      0,
      0
    );

    // If the time has already passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'aduane_daily',
          'Daily Reminders',
          importance: Importance.defaultImportance,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents:
          DateTimeComponents.time, // Repeats daily at this time!
    );
  }

  // ==========================================
  // 3. CANCELLATION (The UX Magic)
  // ==========================================
  static Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }
}
