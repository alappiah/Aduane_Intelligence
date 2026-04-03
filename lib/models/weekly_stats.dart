import 'package:capstone_frontend/state/app_state.dart';

class DailySummary {
  final DateTime date;
  final int steps;
  final int caloriesConsumed;
  final int caloriesBurned;

  DailySummary({
    required this.date,
    required this.steps,
    required this.caloriesConsumed,
    required this.caloriesBurned,
  });

  factory DailySummary.fromJson(Map<String, dynamic> json) {
    return DailySummary(
      date: DateTime.parse(json['date']),
      steps: json['steps'] ?? 0,
      caloriesConsumed: json['calories_consumed'] ?? 0,
      caloriesBurned: json['calories_burned'] ?? 0,
    );
  }
}

class WeeklyStats {
  final List<DailySummary> dailySummary;
  final List<MealEntry> meals;
  final List<WorkoutEntry> workouts;

  WeeklyStats({
    required this.dailySummary,
    required this.meals,
    required this.workouts,
  });
}