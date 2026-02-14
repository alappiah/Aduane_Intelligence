import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isLogin = true; //State to toggle between login and register
  bool rememberMe = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: const Color(0xFFFDE8E9),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),
              const Center(
                child: Text(
                  "Aduane Intelligence",
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w400,
                    color: Colors.black87,
                  ),
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
                    Expanded(child: _buildToggleButton("Login", isLogin)),
                    Expanded(child: _buildToggleButton("Register", !isLogin)),
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
              _buildTextField(hintText: "Enter Email"),

              const SizedBox(height: 24),

              //Password Field
              const Text(
                "Password",
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              _buildTextField(hintText: "Enter Password"),

              const SizedBox(height: 8),

              // Remember me and Forgot password
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: rememberMe,
                        onChanged: (val) => setState(() => rememberMe = val!),
                        activeColor: const Color(0xFF41B9A1),
                      ),
                      const Text("Remember me", style: TextStyle(fontSize: 12)),
                    ],
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      "Forgot Password",
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              //main login button
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
                    Navigator.pushNamed(context, "/home_screen");
                  },
                  child: const Text(
                    "Login",
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // Footer text
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Don't have an account? ",
                      style: TextStyle(color: Colors.grey),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, '/register');
                      },
                      child: const Text(
                        "Register",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
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
        if (title == "Register") {
          //Navigates to the register route defined in main.dart
          Navigator.pushNamed(context, '/register');
        } else {
          setState(() => (title == "Login"));
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

  // Helper widget for text fields
  Widget _buildTextField({required String hintText, bool isPassword = false}) {
    return TextField(
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
