import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:provider/provider.dart';

import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/home_screen.dart';

import 'services/network_helper.dart';
import 'services/notification_service.dart';

import 'state/app_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🌟 1. INITIALIZE NOTIFICATIONS HERE!
  // This tells the phone's OS to get ready to send alerts
  await NotificationService.init();

  final prefs = await SharedPreferences.getInstance();
  final String? savedUserString = prefs.getString('saved_user');

  Widget startingScreen;
  if (savedUserString != null) {
    Map<String, dynamic> userData = jsonDecode(savedUserString);
    startingScreen = HomeScreen(user: userData);
  } else {
    startingScreen = const LoginScreen();
  }

  runApp(
    ChangeNotifierProvider(
      create: (context) => AppState(),
      child: MyApp(initialScreen: startingScreen),
    ),
  );

  await AppState().initHealthTracker();
}

class MyApp extends StatefulWidget {
  final Widget initialScreen;

  const MyApp({super.key, required this.initialScreen});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late StreamSubscription<List<ConnectivityResult>> _networkSubscription;

  @override
  void initState() {
    super.initState();

    // 🌟 2. CALL THE FUNCTION HERE!
    // As soon as the app opens, schedule the morning/evening alerts
    setupDailyStaticReminders();

    // Keeps the passive listener running in the background
    _networkSubscription = Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      if (results.contains(ConnectivityResult.none) || results.isEmpty) {
        showOfflineWarning();
      } else {
        rootScaffoldMessengerKey.currentState?.hideCurrentSnackBar();
      }
    });
  }

  @override
  void dispose() {
    _networkSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Capstone Project",
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      navigatorKey: navigatorKey,
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: widget.initialScreen,
      routes: {
        '/register': (context) => RegisterScreen(),
        '/forgot_password_screen': (context) => ForgotPasswordScreen(),
      },
    );
  }

  // 🌟 (Your function stays exactly the same)
  void setupDailyStaticReminders() {
    final state = AppState();
    // ID 100: Morning Brief at 8:00 AM
    // ID 100: Morning Brief at 8:00 AM
    NotificationService.scheduleDaily(
      id: 100,
      hour: 8,
      title: '☀️ Good Morning!',
      body:
          "You have been active for ${state.daysActive} days! Let's make healthy choices today.",
    );

    // ID 101: Evening Warning at 9:00 PM
    NotificationService.scheduleDaily(
      id: 101,
      hour: 21,
      title: '🏃 Keep Your Run Going!',
      body:
          'The day is almost over. Log your dinner to keep your ${state.daysActive}-day active record going!',
    );

    // ID 201: Breakfast Reminder at 10:00 AM
    NotificationService.scheduleDaily(
      id: 201,
      hour: 10,
      title: '🍳 Breakfast Time!',
      body: 'Did you have Hausa Koko or Waakye today? Don\'t forget to log it.',
    );

    // ID 202: Lunch Reminder at 2:00 PM
    NotificationService.scheduleDaily(
      id: 202,
      hour: 14,
      title: '🍛 Lunch Time!',
      body: 'Fuel up for the afternoon. Log your lunch when you finish eating!',
    );

    // ID 203: Dinner Reminder at 8:00 PM
    NotificationService.scheduleDaily(
      id: 203,
      hour: 20,
      title: '🍲 Dinner Time!',
      body:
          'Time to wind down. Log your dinner to keep your calories accurate.',
    );
  }
}
