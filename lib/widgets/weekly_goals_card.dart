import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import 'custom_card.dart';
import 'weekly_goal_circle.dart';

class WeeklyGoalsCard extends StatelessWidget {
  const WeeklyGoalsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Weekly Progress',
            style: GoogleFonts.nunito(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              WeeklyGoalCircle(
                label: 'Steps',
                percentText: '85%',
                percentValue: 0.85,
                color: AppColors.pink,
              ),
              WeeklyGoalCircle(
                label: 'Calories',
                percentText: '72%',
                percentValue: 0.72,
                color: AppColors.teal,
              ),
            ],
          ),
        ],
      ),
    );
  }
}