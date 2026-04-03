import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dashboard_screen.dart';
import 'chat_screen.dart';
import '../state/app_state.dart';

class HomeScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const HomeScreen({super.key, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  
  // 🌟 We use a late list so the pages are only created ONCE
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();

    // 1. Initialize the pages
    _pages = [
      _buildHomeContent(),
      DashboardScreen(user: widget.user),
    ];

    // 2. 🌟 COLD START FIX: Trigger data fetch immediately
    // This talks to your Render backend the millisecond the app opens.
    Future.microtask(() {
      final userId = widget.user['id'];
      if (userId != null) {
        final state = AppState();
        state.loadUserProfile(userId);
        state.loadDashboardData(userId);
        state.loadWeeklyInsights();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE3EAEF),
      body: SafeArea(
        child: Stack(
          children: [
            // 🌟 3. Use IndexedStack to keep Dashboard 'alive' in the background
            IndexedStack(
              index: _selectedIndex,
              children: _pages,
            ),

            // Floating Navigation Bar
            Positioned(
              bottom: 20,
              left: 24,
              right: 24,
              child: _buildBottomNav(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeContent() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            Text(
              "Welcome ${widget.user['firstName'] ?? 'User'}",
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E1E1E),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Get personalized food recommendations",
              style: TextStyle(color: Colors.black54, fontSize: 14),
            ),
            const SizedBox(height: 30),
            
            // AI Chat Search Bar
            TextField(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(
                      user: widget.user,
                      todayCalories: AppState().totalCaloriesConsumed,
                    ),
                  ),
                );
              },
              readOnly: true,
              decoration: InputDecoration(
                hintText: "What are you craving today?",
                prefixIcon: const Icon(Icons.search, color: Colors.black54),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 25),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          _navItem(0, Icons.home_outlined, "Home"),
          _navItem(1, Icons.person_outlined, "Dashboard"),
        ],
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    bool isSelected = _selectedIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedIndex = index),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0XFF41B9A1) : Colors.white,
            borderRadius: BorderRadius.circular(30),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Colors.black54,
              ),
              if (isSelected) ...[
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}