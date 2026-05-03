import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

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

      await _notificationsPlugin.initialize(initSettings);

      
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('✅ User granted Firebase permission');
      }

      
      
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint("📩 Firebase Message Received in Foreground!");

        
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

    
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint("🖱️ Notification Tapped while in background!");
      // Example: navigatorKey.currentState?.pushNamed('/activity_hub');
    });

    
    RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint("🚀 App opened from a terminated state via notification!");
      
    }
  }

  
  
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
        
        styleInformation: BigTextStyleInformation(
          body,
          contentTitle: title,
          htmlFormatBigText: true,
        ),
      ),
      iOS: const DarwinNotificationDetails(), 
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
