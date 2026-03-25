import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import 'custom_card.dart';
import '../widgets/log_meal_sheet.dart';
import '../widgets/add_workout_sheet.dart';

class SettingsCard extends StatelessWidget {
  final Map<String, dynamic> user; // 🌟 1. Define the user variable here

  const SettingsCard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Settings',
            style: GoogleFonts.nunito(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 16),

          _settingsNavRow(
            icon: Icons.restaurant_rounded,
            iconColor: AppColors.orange,
            iconBg: AppColors.orangeLight,
            label: 'Log Meal',
            onTap: () {
              showLogMealSheet(context, user);
            },
          ),
          _divider(),

          _settingsNavRow(
            icon: Icons.monitor_heart_rounded,
            iconColor: AppColors.orange,
            iconBg: AppColors.orangeLight,
            label: 'Add Workout',
            onTap: () {
              showAddWorkoutSheet(context);
            },
          ),
        ],
      ),
    );
  }

  // The helper method to build each clickable row
  Widget _settingsNavRow({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.nunito(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textLight,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _divider() =>
      Divider(color: AppColors.divider, height: 1, thickness: 1);
}
