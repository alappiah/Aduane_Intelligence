import 'package:flutter/material.dart';
import ''
import 'chat_screen.dart';

class HomeScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const HomeScreen({super.key, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  late final List<Widget> _pages = [
    HomeScreen(user: widget.user),     // Index 0: Your Chat/Home screen
    ProfileScreen(user: widget.user),   // Index 1: Your Profile screen
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE3EAEF),
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    Text(
                      "Welcome ${widget.user['firstName']}", // <-- Dynamically grabs the user's first name
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E1E1E),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Get personalized food recommendation",
                      style: TextStyle(color: Colors.black54, fontSize: 14),
                    ),
                    const SizedBox(height: 30),
                    TextField(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatScreen(user: widget.user), // <-- FIXED: Changed response.data to widget.user
                          ),
                        );
                      },
                      readOnly: true,
                      decoration: InputDecoration(
                        hintText: "What are you craving today?",
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Colors.black54,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 25,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Positioned(
              bottom: 20, // Distance from the bottom of the screen
              left: 24,
              right: 24,
              child: _buildBottomNav(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      height: 70,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(35),
      ),
      child: Row(
        children: [
          //Home tab
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedIndex = 0),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color:
                      _selectedIndex == 0
                          ? const Color(0XFF41B9A1)
                          : Colors.white,
                  borderRadius: BorderRadius.circular(30),
                ),
                height: double.infinity,
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.home_outlined,
                      color:
                          _selectedIndex == 0 ? Colors.white : Colors.black54,
                    ),
                    if (_selectedIndex == 0) const SizedBox(width: 8),
                    if (_selectedIndex == 0)
                      const Text(
                        "Home",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          //Profile tab
          Expanded(
            child: GestureDetector(
              onTap: ( ) => setState(() => _selectedIndex = 1),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color:
                      _selectedIndex == 1
                          ? const Color(0XFF41B9A1)
                          : Colors.white,
                  borderRadius: BorderRadius.circular(30),
                ),
                height: double.infinity,
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person_outlined,
                      color:
                          _selectedIndex == 1 ? Colors.white : Colors.black54,
                    ),
                    if (_selectedIndex == 1) const SizedBox(width: 8),
                    if (_selectedIndex == 1)
                      const Text(
                        "Profile",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}