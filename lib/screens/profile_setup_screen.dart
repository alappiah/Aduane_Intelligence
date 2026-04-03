import 'package:flutter/material.dart';
import '../services/api_service.dart'; // Make sure this path matches where you put api_service.dart
import '../services/network_helper.dart';

class ProfileSetupScreen extends StatefulWidget {
  // 1. ADDED: Variables to catch the data passed from RegisterScreen
  final String email;
  final String password;

  const ProfileSetupScreen({super.key, required this.email, required this.password});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  bool isRegister = true;
  List<String> items = <String>["Hypertension", "Cholesterol", "Diabetes"];
  String? selectedCondition;
  
  // 2. ADDED: State variable to show a loading spinner while waiting for the server
  bool isLoading = false; 

  // 3. ADDED: Controllers to grab the text the user types
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  // 4. ADDED: The function that actually talks to your backend
  void _submitRegistration() async {
    bool hasInternet = await isConnectedToInternet();
    if (!hasInternet) return;

    // Safety check: Make sure they didn't leave anything blank
    if (_firstNameController.text.isEmpty || _lastNameController.text.isEmpty || selectedCondition == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
      return;
    }

    setState(() => isLoading = true); // Turn on loading spinner

    // Send everything to the Python server
    bool success = await ApiService.signupUser(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      email: widget.email, // Grabbed from Screen 1
      password: widget.password, // Grabbed from Screen 1
      healthCondition: selectedCondition!,
    );

    setState(() => isLoading = false); // Turn off loading spinner

    if (success) {
      // If it worked, take them back to the login screen!
      if (mounted) Navigator.pushNamed(context, "/"); 
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Registration failed. Please try again.")));
      }
    }
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
              //First Name Field
              const Text(
                "First Name",
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              _buildTextField(hintText: "Enter First Name", controller: _firstNameController),
              const SizedBox(height: 24),
              //Last Name Field
              const Text(
                "Last Name",
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              _buildTextField(hintText: "Enter Last Name", controller: _lastNameController),
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
                  // 5. ADDED: Connect the button to the function (or disable it if loading)
                  onPressed: isLoading ? null : _submitRegistration,
                  child: isLoading 
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text(
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

  // 6. ADDED: Allow the helper widget to accept the text controllers
  Widget _buildTextField({required String hintText, bool isPassword = false, TextEditingController? controller}) {
    return TextField(
      controller: controller, // <-- Connects the UI to the controller
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