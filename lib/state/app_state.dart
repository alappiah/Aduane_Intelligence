import 'package:flutter/material.dart';

class MealEntry {
  final String name;
  final String mealType;
  final int calories;
  final int carbs;
  final int protein;
  final int fats;
  final String time;

  MealEntry({
    required this.name,
    required this.mealType,
    required this.calories,
    required this.carbs,
    required this.protein,
    required this.fats,
    required this.time,
  });
}

class WorkoutEntry {
  final String name;
  final String type;
  final int durationMinutes;
  final int caloriesBurned;
  final String time;

  WorkoutEntry({
    required this.name,
    required this.type,
    required this.durationMinutes,
    required this.caloriesBurned,
    required this.time,
  });
}

class UserProfile {
  String name;
  String email;
  String dateOfBirth;
  String height;
  String currentWeight;
  String goalWeight;
  String activityLevel;

  UserProfile({
    this.name = 'Sarah Rivera',
    this.email = 'sarah.rivera@email.com',
    this.dateOfBirth = 'March 15, 1995',
    this.height = '5\'6" (168 cm)',
    this.currentWeight = '65.2 kg',
    this.goalWeight = '60.0 kg',
    this.activityLevel = 'Moderately Active',
  });
}

class AppState extends ChangeNotifier {
  // Singleton
  static final AppState _instance = AppState._internal();
  factory AppState() => _instance;
  AppState._internal();

  // Profile
  UserProfile profile = UserProfile();

  // Notifications toggle
  bool notificationsEnabled = true;

  // Meals
  final List<MealEntry> meals = [
    MealEntry(name: 'Grilled Chicken Salad', mealType: 'Lunch', calories: 450, carbs: 20, protein: 45, fats: 12, time: '12:30 PM'),
    MealEntry(name: 'Morning Oatmeal', mealType: 'Breakfast', calories: 320, carbs: 55, protein: 12, fats: 6, time: '7:00 AM'),
  ];

  // Workouts
  final List<WorkoutEntry> workouts = [
    WorkoutEntry(name: 'Morning Run', type: 'Cardio', durationMinutes: 30, caloriesBurned: 320, time: '6:30 AM'),
  ];

  // Computed
  int get totalCaloriesConsumed => meals.fold(0, (sum, m) => sum + m.calories);
  int get totalCaloriesBurned => workouts.fold(0, (sum, w) => sum + w.caloriesBurned);
  int get totalCarbs => meals.fold(0, (sum, m) => sum + m.carbs);
  int get totalProtein => meals.fold(0, (sum, m) => sum + m.protein);
  int get totalFats => meals.fold(0, (sum, m) => sum + m.fats);

  void addMeal(MealEntry meal) {
    meals.insert(0, meal);
    notifyListeners();
  }

  void addWorkout(WorkoutEntry workout) {
    workouts.insert(0, workout);
    notifyListeners();
  }

  void toggleNotifications() {
    notificationsEnabled = !notificationsEnabled;
    notifyListeners();
  }

  void updateProfile(UserProfile updated) {
    profile = updated;
    notifyListeners();
  }
}