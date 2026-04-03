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

import 'state/app_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final String? savedUserString = prefs.getString('saved_user');

  Widget startingScreen;
  if (savedUserString != null) {
    Map<String, dynamic> userData = jsonDecode(savedUserString);
    startingScreen = HomeScreen(user: userData);
  } else {
    startingScreen = const LoginScreen();
  }

  // 🌟 2. Wrap your app in the Provider here!
  runApp(
    ChangeNotifierProvider(
      create: (context) => AppState(),
      child: MyApp(initialScreen: startingScreen),
    ),
  );
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

    // 🌟 Keeps the passive listener running in the background
    _networkSubscription = Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      if (results.contains(ConnectivityResult.none) || results.isEmpty) {
        showOfflineWarning(); // This now safely calls your helper file!
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

      // 🌟 Connects to the key in your helper file
      scaffoldMessengerKey: rootScaffoldMessengerKey,

      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: widget.initialScreen,
      routes: {
        '/register': (context) => RegisterScreen(),
        '/forgot_password_screen': (context) => ForgotPasswordScreen(),
      },
    );
  }
}
