import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

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
                    const Text(
                      "Welcome Simon",
                      style: TextStyle(
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
                        Navigator.pushNamed(context, "/chat_screen");
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
        // child: Padding(
        //   padding: const EdgeInsets.symmetric(horizontal: 24.0),
        //   child: Column(
        //     crossAxisAlignment: CrossAxisAlignment.start,
        //     children: [
        //       const SizedBox(height: 60),
        //       //Welcome header
        //       const Text(
        //         "Welcome Simon",
        //         style: TextStyle(
        //           fontSize: 28,
        //           fontWeight: FontWeight.bold,
        //           color: Color(0xFF1E1E1E),
        //         ),
        //       ),
        //       const SizedBox(height: 30),
        //       const Text(
        //         "Get personalized food recommedation",
        //         style: TextStyle(color: Colors.black54, fontSize: 14),
        //       ),
        //       const SizedBox(height: 30),

        //       //SizedBox
        //       TextField(
        //         decoration: InputDecoration(
        //           hintText: "What are you craving today?",
        //           prefixIcon: const Icon(Icons.search, color: Colors.black54),
        //           filled: true,
        //           fillColor: Colors.white.withOpacity(0.5),
        //           border: OutlineInputBorder(
        //             borderRadius: BorderRadius.circular(30),
        //             borderSide: BorderSide.none,
        //           ),
        //           contentPadding: const EdgeInsets.symmetric(vertical: 15),
        //         ),
        //       ),
        //       const SizedBox(height: 40),
        //       // Grid of Food/Category Cards
        //       Expanded(
        //         child: GridView.builder(
        //           gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        //             crossAxisCount: 2, // Two items per row
        //             crossAxisSpacing: 20,
        //             mainAxisSpacing: 20,
        //             childAspectRatio: 1, // Square cards
        //           ),
        //           itemCount: 4, // Number of placeholder cards
        //           itemBuilder: (context, index) {
        //             return Container(
        //               decoration: BoxDecoration(
        //                 color: const Color(0xFFE8D3D4), // Slightly darker pink for cards
        //                 borderRadius: BorderRadius.circular(25),
        //               ),
        //             );
        //           },
        //         ),
        //       ),
        //       //Custom Navigation bar
        //       _buildBottomNav(),
        //       const SizedBox(height: 20)
        //     ],
        //   ),
        // ),
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
              onTap: () => setState(() => _selectedIndex = 1),
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
