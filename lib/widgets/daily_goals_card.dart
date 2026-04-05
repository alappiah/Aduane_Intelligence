import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../state/app_state.dart';
import 'custom_card.dart';
import 'daily_goal_circle.dart';

class DailyGoalsCard extends StatefulWidget {
  const DailyGoalsCard({super.key});

  @override
  State<DailyGoalsCard> createState() => _DailyGoalsCardState();
}

class _DailyGoalsCardState extends State<DailyGoalsCard> {
  @override
  void initState() {
    super.initState();
    // Listen for changes in AppState (meals logged, steps taken, or profile updated!)
    AppState().addListener(_onStateChanged);
  }

  @override
  void dispose() {
    AppState().removeListener(_onStateChanged);
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final state = AppState();
    final profile = state.profile;

    // 🌟 1. The Math is now Daily! No more multiplying by 7.
    final int dailyCalorieGoal = profile.goalCalories;
    final int dailyStepGoal = profile.goalSteps;

    // 🌟 2. Get Current Progress for TODAY
    final int currentCalories = state.totalCaloriesConsumed;
    final int currentSteps = state.dailySteps; // Driven by the hardware pedometer!

    // 🌟 3. Calculate Percentages
    double caloriePercent = dailyCalorieGoal > 0 ? currentCalories / dailyCalorieGoal : 0.0;
    double stepPercent = dailyStepGoal > 0 ? currentSteps / dailyStepGoal : 0.0;

    // Cap at 1.0 (100%) so the circle animation doesn't break
    if (caloriePercent > 1.0) caloriePercent = 1.0;
    if (stepPercent > 1.0) stepPercent = 1.0;

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center, // Centered for the new text
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Daily Progress',
              style: GoogleFonts.nunito(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              DailyGoalCircle(
                label: 'Steps',
                percentText: '${(stepPercent * 100).toInt()}%',
                percentValue: stepPercent,
                color: AppColors.pink,
                isBudgetMode: false, // Normal target
              ),
              DailyGoalCircle(
                label: 'Calories',
                percentText: '${(caloriePercent * 100).toInt()}%',
                percentValue: caloriePercent,
                color: AppColors.teal,
                isBudgetMode: true, // Dietary Limit
              ),
            ],
          ),
          
          // 🌟 THE NEW UI HINT!
          // This will dynamically appear and disappear based on the vault
          if (currentSteps == 0) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.bg, // A soft gray/light background
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                "0 steps yet? Let's get moving!\n(If you have walked, ensure Samsung Health is synced)",
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  color: AppColors.textMedium,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}