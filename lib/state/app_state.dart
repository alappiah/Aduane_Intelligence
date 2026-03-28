import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/api_service.dart'; // 🌟 Make sure this path matches your project!

class MealEntry {
  final String name;
  final String mealType;
  final int calories;
  final int carbs;
  final int protein;
  final int fats;
  final int sodium;
  final int sugar;
  final String time;

  MealEntry({
    required this.name,
    required this.mealType,
    required this.calories,
    required this.carbs,
    required this.protein,
    required this.fats,
    required this.sodium,
    required this.sugar,
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
  int goalCalories;
  int goalSteps;

  UserProfile({
    this.name = 'Sarah Rivera',
    this.email = 'sarah.rivera@email.com',
    this.dateOfBirth = 'March 15, 1995',
    this.height = '168',
    this.currentWeight = '65',
    this.goalWeight = '60',
    this.activityLevel = 'Moderately Active',
    this.goalCalories = 2000,
    this.goalSteps = 10000,
  });
}

class AppState extends ChangeNotifier {
  // Singleton
  static final AppState _instance = AppState._internal();
  factory AppState() {
    return _instance;
  }

  AppState._internal() {
    _initPedometer();
  }

  // Profile
  UserProfile profile = UserProfile();
  bool notificationsEnabled = true;

  // 🌟 APP STATE & HARDWARE TRACKING
  int? currentUserId; // Added so the pedometer knows who is walking
  int dailySteps = 0;
  int daysActive = 0;
  int _pedometerBaseline = 0; // 🌟 The Midnight Math baseline
  bool _isBaselineSet = false; // 🌟 Tracks if we've done the math yet today

  String stepStatus = '?';
  late Stream<StepCount> _stepCountStream;
  late Stream<PedestrianStatus> _pedestrianStatusStream;

  // Meals - Now starts empty because we load it from the database!
  final List<MealEntry> meals = [];

  // Workouts
  final List<WorkoutEntry> workouts = [];

  // Computed Macros
  int get totalCaloriesConsumed => meals.fold(0, (sum, m) => sum + m.calories);
  int get totalCaloriesBurned =>
      workouts.fold(0, (sum, w) => sum + w.caloriesBurned);
  int get totalCarbs => meals.fold(0, (sum, m) => sum + m.carbs);
  int get totalProtein => meals.fold(0, (sum, m) => sum + m.protein);
  int get totalFats => meals.fold(0, (sum, m) => sum + m.fats);
  int get totalSodium => meals.fold(0, (sum, m) => sum + m.sodium);
  int get totalSugar => meals.fold(0, (sum, m) => sum + m.sugar);

  // ---------------------------------------------------------
  // 🌟 THE PROFILE LOADER
  // ---------------------------------------------------------
  Future<void> loadUserProfile(int userId) async {
    currentUserId = userId; // Save this just in case!
    final data = await ApiService.fetchUserProfile(userId);

    if (data != null) {
      // Combine first and last name safely
      String firstName = data['firstName'] ?? '';
      String lastName = data['lastName'] ?? '';
      String fullName = [
        firstName,
        lastName,
      ].where((e) => e.isNotEmpty).join(' ');

      // Overwrite the hardcoded profile with the real database data!
      profile = UserProfile(
        name: fullName.isNotEmpty ? fullName : 'Unknown User',
        email: data['email'] ?? '',
        dateOfBirth: data['dateOfBirth'] ?? '',
        height: '${data['height_cm'] ?? 0}',
        currentWeight: '${data['current_weight_kg'] ?? 0}',
        goalWeight: '${data['goal_weight_kg'] ?? 0}',
        activityLevel: data['activity_level'] ?? 'Moderately Active',
        goalCalories: data['goal_calories'] ?? 2000,
        goalSteps: data['goal_steps'] ?? 10000,
      );

      notifyListeners(); // 🌟 Tell the UI to update with the real name!
    }
  }

  // ---------------------------------------------------------
  // 🌟 THE DASHBOARD LOADER
  // ---------------------------------------------------------
  Future<void> loadDashboardData(int userId) async {
    currentUserId = userId;
    final data = await ApiService.fetchTodayDashboard(userId);

    if (data != null) {
      dailySteps = data['steps'] ?? 0;
      daysActive = data['daysActive'] ?? 0;
      _isBaselineSet = false;

      // Load Meals
      meals.clear();
      if (data['meals'] != null) {
        for (var m in data['meals']) {
          meals.add(
            MealEntry(
              name: m['name'],
              mealType: m['mealType'],
              calories: m['calories'],
              carbs: m['carbs'],
              protein: m['protein'],
              fats: m['fats'],
              sodium: m['sodium'],
              sugar: m['sugar'],
              time: m['time'],
            ),
          );
        }
      }

      // 🌟 NEW: Load Workouts
      workouts.clear();
      if (data['workouts'] != null) {
        for (var w in data['workouts']) {
          workouts.add(
            WorkoutEntry(
              name: w['name'],
              type: w['type'],
              durationMinutes: w['durationMinutes'],
              caloriesBurned: w['caloriesBurned'],
              time: w['time'],
            ),
          );
        }
      }

      notifyListeners();
    }
  }

  // ---------------------------------------------------------
  // 🌟 THE PEDOMETER LOGIC
  // ---------------------------------------------------------
  Future<void> _initPedometer() async {
    PermissionStatus status = await Permission.activityRecognition.request();

    if (status.isGranted) {
      _pedestrianStatusStream = Pedometer.pedestrianStatusStream;
      _stepCountStream = Pedometer.stepCountStream;

      _pedestrianStatusStream.listen((PedestrianStatus event) {
        stepStatus = event.status;
        notifyListeners();
      }, onError: (error) => print("Pedestrian Status Error: $error"));

      _stepCountStream.listen((StepCount event) {
        int hardwareSteps = event.steps;

        // 🌟 THE MIDNIGHT MATH 🌟
        if (!_isBaselineSet) {
          // Calculate difference between phone's total and today's database total
          _pedometerBaseline = hardwareSteps - dailySteps;
          _isBaselineSet = true;
        }

        // Live update the steps
        dailySteps = hardwareSteps - _pedometerBaseline;
        notifyListeners();

        // 🌟 SILENT AUTO-SYNC 🌟
        // Ping the database every 50 steps so we don't lose progress
        if (currentUserId != null && dailySteps > 0 && dailySteps % 50 == 0) {
          ApiService.syncStepsToDatabase(
            userId: currentUserId!,
            steps: dailySteps,
          );
        }
      }, onError: (error) => print("Step Count Error: $error"));
    } else {
      print("Permission to access activity recognition was denied.");
    }
  }

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
