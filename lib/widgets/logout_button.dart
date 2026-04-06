import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart'; // 🌟 Added for clearing storage

import '../theme/app_colors.dart';
import '../screens/login_screen.dart';
import '../services/api_service.dart'; // 🌟 Added to sync steps
import '../state/app_state.dart'; // 🌟 Added to get and reset steps

class LogoutButton extends StatelessWidget {
  const LogoutButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.pinkLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.pink.withOpacity(0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showLogoutConfirmation(context),
          borderRadius: BorderRadius.circular(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.logout_rounded, color: AppColors.pink, size: 20),
              const SizedBox(width: 8),
              Text(
                'Log Out',
                style: GoogleFonts.nunito(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.pink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: AppColors.bg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.pinkLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    color: AppColors.pink,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Log Out',
                  style: GoogleFonts.nunito(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Are you sure you want to log out of your account?',
                  style: GoogleFonts.nunito(
                    fontSize: 15,
                    color: AppColors.textMedium,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Confirm logout
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    // 🌟 1. MADE THIS ONPRESSED ASYNC
                    onPressed: () async {
                      // 2. Close the dialog immediately so it feels fast
                      Navigator.pop(dialogContext);

                      // 🌟 3. GRAB DATA & SYNC TO DATABASE
                      final appState = AppState();
                      final currentSteps = appState.dailySteps;
                      // Note: Adjust 'id' if your profile object uses a different variable name for the user ID (like userId)
                      final userId = appState.currentUserId;
                      final dailyActiveCalories = appState.dailyActiveCalories;

                      if (userId != null) {
                        await ApiService.syncStepsToDatabase(
                          userId: userId,
                          steps: currentSteps,
                          calories: dailyActiveCalories,
                        );
                      }

                      // 🌟 4. CLEAR LOCAL HARD DRIVE (Fixes auto-login bug)
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.remove('saved_user');

                      // 🌟 5. RESET LOCAL STATE
                      appState.dailySteps = 0;
                      // If you have a method to clear the whole profile, call it here!

                      // 6. SHOW SNACKBAR & NAVIGATE (Must check mounted after using await)
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'You have been logged out.',
                              style: GoogleFonts.nunito(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            backgroundColor: AppColors.teal,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );

                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                          (route) => false,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.pink,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Yes, Log Out',
                      style: GoogleFonts.nunito(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Cancel
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textMedium,
                      side: const BorderSide(
                        color: AppColors.divider,
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.nunito(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
