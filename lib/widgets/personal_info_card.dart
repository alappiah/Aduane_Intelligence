import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import 'custom_card.dart';
import 'edit_profile_sheet.dart'; // Assuming this is also in your widgets folder

class PersonalInfoCard extends StatelessWidget {
  final Map<String, dynamic> user;

  const PersonalInfoCard({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    
    final String dob = user['dateOfBirth'] ?? AppState().profile.dateOfBirth;
    final String height = user['height'] ?? AppState().profile.height;
    final String weight = user['currentWeight'] ?? AppState().profile.currentWeight;
    final String goal = user['goalWeight'] ?? AppState().profile.goalWeight;
    final String activity = user['activityLevel'] ?? AppState().profile.activityLevel;

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Personal Information',
                style: GoogleFonts.nunito(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
              GestureDetector(
                onTap: () => showEditProfileSheet(context, user),
                child: Text(
                  'Edit',
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.teal,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _infoRow(
            Icons.cake_rounded,
            AppColors.orange,
            AppColors.orangeLight,
            'Date of Birth',
            dob,
          ),
          _divider(),
          _infoRow(
            Icons.height_rounded,
            AppColors.teal,
            AppColors.tealLight,
            'Height',
            height,
          ),
          _divider(),
          _infoRow(
            Icons.monitor_weight_outlined,
            AppColors.pink,
            AppColors.pinkLight,
            'Current Weight',
            weight,
          ),
          _divider(),
          _infoRow(
            Icons.flag_rounded,
            AppColors.purple,
            AppColors.purpleLight,
            'Goal Weight',
            goal,
          ),
          _divider(),
          _infoRow(
            Icons.self_improvement_rounded,
            AppColors.orange,
            AppColors.orangeLight,
            'Activity Level',
            activity,
          ),
        ],
      ),
    );
  }

  // Brought the helper method over so this file can use it!
  Widget _infoRow(
    IconData icon,
    Color iconColor,
    Color iconBg,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    color: AppColors.textMedium,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textLight,
            size: 20,
          ),
        ],
      ),
    );
  }

  // Brought the divider over as well
  Widget _divider() => Divider(
        color: AppColors.divider,
        height: 1,
        thickness: 1,
      );
}