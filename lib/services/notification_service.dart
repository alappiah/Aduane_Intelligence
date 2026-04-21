import 'package:firebase_messaging/firebase_messaging.dart'; // 🌟 Add this
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // 🌟 NEW: Firebase Messaging Instance
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static Future<void> init() async {
    try {
      tz.initializeTimeZones();

      // 1. Local Notification Settings
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

      await _notificationsPlugin.initialize(initSettings);

      // 2. Request Firebase Permissions (Android 13+ & iOS)
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('✅ User granted Firebase permission');
      }

      // 3. Handle Foreground Messages
      // This is crucial! Without this, if the app is open, nothing happens
      // when a Firebase message arrives.
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint("📩 Firebase Message Received in Foreground!");

        // We use your existing local notification function to show the "Popup"
        if (message.notification != null) {
          showInstantNotification(
            id: message.hashCode,
            title: message.notification!.title ?? "Aduane Intelligence",
            body: message.notification!.body ?? "",
          );
        }
      });
    } catch (e) {
      debugPrint("⚠️ Notification Init Failed: $e");
    }

    // 1. Handling the tap when the app is in the BACKGROUND
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint("🖱️ Notification Tapped while in background!");
      // Example: navigatorKey.currentState?.pushNamed('/activity_hub');
    });

    // 2. Handling the tap when the app was COMPLETELY CLOSED (Terminated)
    RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint("🚀 App opened from a terminated state via notification!");
      // You can handle logic here to deep-link to a specific screen
    }
  }

  // 🌟 NEW: Get the Device Address (Token)
  // Call this after the user logs in to send their token to your Python backend
  static Future<String?> getDeviceToken() async {
    try {
      String? token = await _messaging.getToken();
      debugPrint("📱 FCM Device Token: $token");
      return token;
    } catch (e) {
      debugPrint("❌ Failed to get FCM token: $e");
      return null;
    }
  }

  // ==========================================
  // 1. INSTANT NOTIFICATIONS (Used for local & Firebase foreground)
  // ==========================================
  static Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    // 1. Remove 'const' from the beginning
    NotificationDetails details = NotificationDetails(
      android: AndroidNotificationDetails(
        'aduane_channel',
        'Aduane Alerts',
        importance: Importance.max,
        priority: Priority.high,
        // 👇 2. ADD THIS BLOCK TO FIX THE ARROW 👇
        styleInformation: BigTextStyleInformation(
          body,
          contentTitle: title,
          htmlFormatBigText: true,
        ),
      ),
      iOS: const DarwinNotificationDetails(), // You can move const down here
    );
    await _notificationsPlugin.show(id, title, body, details);
  }

  // ==========================================
  // 2. SCHEDULED DAILY NOTIFICATIONS (Meals/Reminders)
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
      0,
    );

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
      // 🌟 Pro-tip: Use .exactAllowWhileIdle if you need 8 AM to be EXACT
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }
}
