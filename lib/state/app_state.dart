import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../services/network_helper.dart';
import 'dart:async';

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
  factory AppState() => _instance;

  StreamSubscription<StepCount>? _stepCountSubscription;
  StreamSubscription<PedestrianStatus>? _pedestrianStatusSubscription;

  // ✅ Guard so _initPedometer can never run twice
  bool _pedometerInitialized = false;

  AppState._internal() {
    _initPedometer();
  }

  // Profile
  UserProfile profile = UserProfile();
  bool notificationsEnabled = true;

  // App State & Hardware Tracking
  int? currentUserId;
  int dailySteps = 0;
  int _lastSyncedSteps = 0; // 🌟 NEW: Tracker for threshold syncing
  int daysActive = 0;
  String stepStatus = '?';

  // Meals & Workouts
  final List<MealEntry> meals = [];
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
  // Profile Loader
  // ---------------------------------------------------------
  Future<void> loadUserProfile(int userId) async {
    currentUserId = userId;
    final data = await ApiService.fetchUserProfile(userId);

    if (data != null) {
      String firstName = data['firstName'] ?? '';
      String lastName = data['lastName'] ?? '';
      String fullName = [
        firstName,
        lastName,
      ].where((e) => e.isNotEmpty).join(' ');

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

      notifyListeners();
    }
  }

  // ---------------------------------------------------------
  // Dashboard Loader
  // ---------------------------------------------------------
  Future<void> loadDashboardData(int userId) async {
    bool hasInternet = await isConnectedToInternet();
    if (!hasInternet) return;

    currentUserId = userId;
    final data = await ApiService.fetchTodayDashboard(userId);

    if (data != null) {
      final int dbSteps = data['steps'] ?? 0;
      daysActive = data['daysActive'] ?? 0;

      // ✅ If the cloud has MORE steps than what we have locally
      // (e.g. after reinstall), inherit the cloud value and update
      // SharedPreferences so the pedometer math stays correct.
      if (dbSteps > dailySteps) {
        final prefs = await SharedPreferences.getInstance();
        final int currentAccumulated = prefs.getInt('ped_accumulated') ?? 0;

        if (dbSteps > currentAccumulated) {
          await prefs.setInt('ped_accumulated', dbSteps);
          // Force the baseline to recalculate on the next pedometer tick
          await prefs.remove('ped_baseline');
        }

        dailySteps = dbSteps;
        _lastSyncedSteps =
            dbSteps; // 🌟 NEW: Update sync tracker when loading from cloud
        notifyListeners();
      }

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

      // Load Workouts
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
  // Pedometer Logic
  // ---------------------------------------------------------
  Future<void> _initPedometer() async {
    // ✅ Hard guard — if already running, do nothing
    if (_pedometerInitialized) {
      print("⚠️ Pedometer already running, skipping re-init.");
      return;
    }

    PermissionStatus status = await Permission.activityRecognition.request();
    print("🔑 Activity Recognition Permission: $status");

    if (status.isGranted) {
      _pedometerInitialized = true;

      _pedestrianStatusSubscription = Pedometer.pedestrianStatusStream.listen(
        (PedestrianStatus event) {
          stepStatus = event.status;
          notifyListeners();
        },
        onError: (error) => print("Pedestrian Status Error: $error"),
        cancelOnError: false,
      );

      _stepCountSubscription = Pedometer.stepCountStream.listen(
        (StepCount event) async {
          final int hardwareSteps = event.steps;
          print("👟 Raw hardware steps: $hardwareSteps");

          final prefs = await SharedPreferences.getInstance();
          final String today = DateTime.now().toIso8601String().substring(
            0,
            10,
          );

          final String? savedDate = prefs.getString('ped_date');
          int savedBaseline = prefs.getInt('ped_baseline') ?? hardwareSteps;
          int accumulatedSteps = prefs.getInt('ped_accumulated') ?? 0;

          // Midnight rollover — reset for new day
          if (savedDate != today) {
            print("🌙 New day detected, resetting pedometer baseline.");
            savedBaseline = hardwareSteps;
            accumulatedSteps = 0;
            await prefs.setString('ped_date', today);
            await prefs.setInt('ped_baseline', savedBaseline);
            await prefs.setInt('ped_accumulated', accumulatedSteps);
          }
          // Phone reboot — hardware counter restarted from a lower number
          else if (hardwareSteps < savedBaseline) {
            print(
              "⚠️ Pedometer reset detected, locking in $accumulatedSteps steps.",
            );
            accumulatedSteps = dailySteps;
            savedBaseline = hardwareSteps;
            await prefs.setInt('ped_baseline', savedBaseline);
            await prefs.setInt('ped_accumulated', accumulatedSteps);
          }

          dailySteps = accumulatedSteps + (hardwareSteps - savedBaseline);
          notifyListeners();

          // 🌟 THE FIX: Silent background sync using the Threshold Method
          if (currentUserId != null &&
              dailySteps > 0 &&
              (dailySteps - _lastSyncedSteps >= 50)) {
            print(
              "🔄 Threshold reached! Syncing $dailySteps steps to database...",
            );
            ApiService.syncStepsToDatabase(
              userId: currentUserId!,
              steps: dailySteps,
            );
            _lastSyncedSteps = dailySteps; // 🌟 Reset the tracker after syncing
          }
        },
        onError: (error) => print("Step Count Error: $error"),
        cancelOnError: false,
      );
    } else {
      print("❌ Permission to access activity recognition was denied.");
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

  // ---------------------------------------------------------
  // Logout Wiper
  // ---------------------------------------------------------
  // ✅ DO NOT cancel the pedometer or call _initPedometer here.
  // The hardware stream survives logout/login — only the user data resets.
  void resetState() {
    currentUserId = null;
    dailySteps = 0;
    _lastSyncedSteps = 0; // 🌟 NEW: Wipe the tracker on logout
    daysActive = 0;
    meals.clear();
    workouts.clear();
    profile = UserProfile();
    notifyListeners();
  }
}
