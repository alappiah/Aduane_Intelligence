import 'package:flutter/material.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  bool isRegister = true;
  List<String> items = <String>["Hypertension", "Cholesterol", "Diabetes"];
  String? selectedCondition;
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
                  "Enter your profile information",
                  style: TextStyle(
                    fontSize: 20,
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
                "First Name",
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              _buildTextField(hintText: "Enter First Name"),
              const SizedBox(height: 24),
              //Password Field
              const Text(
                "Last Name",
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              _buildTextField(hintText: "Enter Last Name"),
              const SizedBox(height: 24),
              const Text(
                "Health Condition",
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: selectedCondition,
                hint: const Text("Select Condition"),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFFC3C3C3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                ),
                items:
                    items.map((String item) {
                      return DropdownMenuItem<String>(
                        value: item,
                        child: Text(item),
                      );
                    }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    selectedCondition = newValue;
                  });
                },
              ),
              const SizedBox(height: 24),
              //main register button
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
                    "Register",
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
