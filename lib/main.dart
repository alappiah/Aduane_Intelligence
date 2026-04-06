import 'dart:async';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:provider/provider.dart';
import 'package:workmanager/workmanager.dart';

import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/home_screen.dart';

import 'services/network_helper.dart';
import 'services/notification_service.dart';

import 'state/app_state.dart';
import 'firebase_options.dart';

// ==========================================
// 1. BACKGROUND HANDLERS (Must be top-level)
// ==========================================

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint("Handling a background message: ${message.messageId}");
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    debugPrint("🔋 Workmanager: Waking up to sync health data...");

    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Get the UserID from storage (AppState is empty in the background!)
    final prefs = await SharedPreferences.getInstance();
    final String? userJson = prefs.getString('saved_user');

    if (userJson != null) {
      final userData = jsonDecode(userJson);
      final int userId =
          userData['id'] ?? userData['user_id']; // Adapt to your JSON keys

      // Run the sync
      final state = AppState();
      state.currentUserId = userId;
      await state.initHealthTracker();
      await state.fetchTodaySteps();

      debugPrint("✅ Background Sync Complete for User $userId");
    }

    return Future.value(true);
  });
}

// ==========================================
// 2. MAIN APP ENTRY POINT
// ==========================================

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase & FCM
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await NotificationService.init();

  // Initialize Workmanager for Background Sync
  Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: false, // 🌟 Set to false before submitting your capstone!
  );

  Workmanager().registerPeriodicTask(
    "1",
    "healthSyncTask",
    frequency: const Duration(minutes: 15),
    constraints: Constraints(networkType: NetworkType.connected),
  );

  // Initialize App State
  final appState = AppState();
  await appState.initHealthTracker();

  // Check Persistent Login
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
    ChangeNotifierProvider.value(
      value: appState,
      child: MyApp(initialScreen: startingScreen),
    ),
  );
}

// ==========================================
// 3. ROOT APP WIDGET
// ==========================================

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

    // // 🌟 Wait for the widget tree to build, then grab the REAL AppState
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   final state = Provider.of<AppState>(context, listen: false);

    // });

    // Network connectivity listener
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
      title: "Aduane Intelligence",
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      navigatorKey: navigatorKey,
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: widget.initialScreen,
      routes: {
        '/register': (context) => const RegisterScreen(),
        '/forgot_password_screen': (context) => const ForgotPasswordScreen(),
      },
    );
  }

}


