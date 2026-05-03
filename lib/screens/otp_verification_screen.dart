import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import 'new_password_screen.dart'; 


class OtpVerificationScreen extends StatefulWidget {
  // Require the email from the previous screen
  final String email;
  
  const OtpVerificationScreen({super.key, required this.email});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final pinController = TextEditingController();
  final focusNode = FocusNode();

  @override
  void dispose() {
    pinController.dispose();
    focusNode.dispose();
    super.dispose();
  }

  // A helper to move to the next screen
  void _goToNewPasswordScreen(String pin) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NewPasswordScreen(
          email: widget.email, 
          resetCode: pin,
        ),
      ),
    );
    print("Moving to new password screen with email: ${widget.email} and pin: $pin");
  }

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 56,
      height: 56,
      textStyle: const TextStyle(
        fontSize: 22,
        color: Colors.black,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade400),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text("Verify OTP"),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "Enter the 6-digit code sent to\n${widget.email}",
              style: const TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            
            Pinput(
              length: 6, 
              controller: pinController,
              focusNode: focusNode,
              defaultPinTheme: defaultPinTheme,
              focusedPinTheme: defaultPinTheme.copyWith(
                decoration: defaultPinTheme.decoration!.copyWith(
                  border: Border.all(color: Colors.blue, width: 2),
                ),
              ),
              onCompleted: (pin) {
                print("User entered: $pin");
                // Auto-navigate when they finish typing the 6th digit
                _goToNewPasswordScreen(pin); 
              },
            ),
            
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (pinController.text.length == 6) {
                    _goToNewPasswordScreen(pinController.text);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter all 6 digits')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text("Verify"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}