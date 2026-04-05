import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

// 🌟 1. The Global Key
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey = 
    GlobalKey<ScaffoldMessengerState>();
    final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// 🌟 2. The Warning Function
void showOfflineWarning() {
  rootScaffoldMessengerKey.currentState?.showSnackBar(
    SnackBar(
      content: const Row(
        children: [
          Icon(Icons.wifi_off_rounded, color: Colors.white),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'No Internet Connection. Please check your Wi-Fi or cellular data.',
              style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.redAccent,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 4), 
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}

// 🌟 3. The Active Check
Future<bool> isConnectedToInternet() async {
  final List<ConnectivityResult> results = await Connectivity().checkConnectivity();
  if (results.contains(ConnectivityResult.none) || results.isEmpty) {
    showOfflineWarning();
    return false;
  }
  return true;
}