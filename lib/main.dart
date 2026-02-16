import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/profile_setup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/chat_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Capstone Project",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
        initialRoute: "/",
        routes: {
          '/': (context) => const LoginScreen(),
          '/register': (context) => RegisterScreen(),
          '/profile_setup_screen' :  (context) => ProfileSetupScreen(),
          '/home_screen' : (context) => HomeScreen(),
          '/chat_screen' : (context) => ChatScreen(),
        },
    );
  }
}
