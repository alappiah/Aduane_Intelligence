import 'package:flutter/material.dart';
import 'profile_setup_screen.dart'; // Make sure this points to your Profile Setup file

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool isRegister = true;

  // 1. ADDED: Controllers to "listen" to what the user types
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // ADDED: Good practice to clean up controllers when the screen closes
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),
              const Center(
                child: Text(
                  "Create Your Account",
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w400,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Already have an account? ",
                      style: TextStyle(color: Colors.grey),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, '/');
                      },
                      child: const Text(
                        "Login",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              //Login/Register toggle
              Container(
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Row(
                  children: [
                    Expanded(child: _buildToggleButton("Login", !isRegister)),
                    Expanded(child: _buildToggleButton("Register", isRegister)),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              //Email Field
              const Text(
                "Email Address",
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              // 2. ADDED: Passed the email controller here
              _buildTextField(
                hintText: "Enter Email",
                controller: _emailController,
              ),
              const SizedBox(height: 24),
              //Password Field
              const Text(
                "Password",
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              // 2. ADDED: Passed the password controller here
              _buildTextField(
                hintText: "Enter Password",
                isPassword: true,
                controller: _passwordController,
              ),
              const SizedBox(height: 40),
              //main continue button
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF41B9A1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: () {
                    String email = _emailController.text.trim();
                    String password = _passwordController.text;

                    // 1. Define the Regex
                    final passwordRegEx = RegExp(
                      r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{8,}$',
                    );

                    // 2. Run the check
                    if (!passwordRegEx.hasMatch(password)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Password must be at least 8 characters and include both letters and numbers.",
                          ),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                      return; // Stop here! Don't go to the next screen.
                    }

                    // 3. If valid, proceed to Profile Setup
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => ProfileSetupScreen(
                              email: email,
                              password: password,
                            ),
                      ),
                    );
                  },
                  child: const Text(
                    "Continue",
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  //Helper widget for the Toggle button
  Widget _buildToggleButton(String title, bool isActive) {
    return GestureDetector(
      onTap: () {
        if (title == "Login") {
          //Navigates to the register route defined in main.dart
          Navigator.pop(context);
        } else {
          setState(() => isRegister = true);
        }
      },
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF5BB29B) : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.black54,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // 4. ADDED: 'TextEditingController? controller' to the parameters so it can accept the controllers
  Widget _buildTextField({
    required String hintText,
    bool isPassword = false,
    TextEditingController? controller,
  }) {
    return TextField(
      controller:
          controller, // <-- ADDED: Connects the text field to the controller
      obscureText: isPassword,
      decoration: InputDecoration(
        filled: true,
        fillColor: Color(0xFFC3C3C3),
        hintText: hintText,
        suffixIcon:
            isPassword
                ? const Icon(
                  Icons.visibility_off_outlined,
                  color: Colors.black54,
                )
                : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
      ),
    );
  }
}
