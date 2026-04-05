import 'dart:convert';
import 'dart:async';

import 'package:capstone_frontend/models/weekly_stats.dart';
import 'package:flutter/material.dart';
import 'package:health/health.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/api_service.dart';
import '../services/network_helper.dart';
import '../services/notification_service.dart';

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
  String firstName;
  String lastName;
  String email;
  String healthCondition;
  String dateOfBirth;
  String height;
  String currentWeight;
  String goalWeight;
  String activityLevel;
  int goalCalories;
  int goalSteps;

  UserProfile({
    this.firstName = 'Sarah',
    this.lastName = 'Rivera',
    this.email = 'sarah.rivera@email.com',
    this.healthCondition = 'None',
    this.dateOfBirth = 'March 15, 1995',
    this.height = '168',
    this.currentWeight = '65',
    this.goalWeight = '60',
    this.activityLevel = 'Moderately Active',
    this.goalCalories = 2000,
    this.goalSteps = 10000,
  });

  String get fullName => "$firstName $lastName".trim();
}

// 🌟 ADDED `with WidgetsBindingObserver` for the Catch-Up Pattern
class AppState extends ChangeNotifier with WidgetsBindingObserver {
  static final AppState _instance = AppState._internal();
  factory AppState() => _instance;

  bool _healthInitialized = false;

  AppState._internal();

  UserProfile profile = UserProfile();
  bool notificationsEnabled = true;

  bool _hasShownSettingsDialog = false;
  bool _hasWarnedAboutSourceApp = false;
  bool _isFetchingSteps = false;
  bool _hasHealthPermissions = false;

  List<DailySummary> weeklyDailySummary = [];
  List<MealEntry> weeklyMealHistory = [];
  List<WorkoutEntry> weeklyWorkoutHistory = [];
  bool isLoadingHistory = false;
  List<String> achievements = [];

  int? currentUserId;
  int dailySteps = 0;
  int _lastSyncedSteps = 0;
  int daysActive = 0;
  int dailyActiveCalories = 0;

  final List<MealEntry> meals = [];
  final List<WorkoutEntry> workouts = [];

  int get totalCaloriesConsumed => meals.fold(0, (sum, m) => sum + m.calories);
  int get totalCaloriesBurned =>
      workouts.fold(0, (sum, w) => sum + w.caloriesBurned) +
      dailyActiveCalories;

  int get totalCarbs => meals.fold(0, (sum, m) => sum + m.carbs);
  int get totalProtein => meals.fold(0, (sum, m) => sum + m.protein);
  int get totalFats => meals.fold(0, (sum, m) => sum + m.fats);
  int get totalSodium => meals.fold(0, (sum, m) => sum + m.sodium);
  int get totalSugar => meals.fold(0, (sum, m) => sum + m.sugar);

  // =========================================================
  // 🌟 DYNAMIC NOTIFICATION SCHEDULER
  // =========================================================
  void _scheduleDynamicReminders(int currentDaysActive) {
    // ID 100: Morning Brief at 8:00 AM
    NotificationService.scheduleDaily(
      id: 100,
      hour: 8,
      title: '☀️ Good Morning!',
      body:
          'You have been active for $currentDaysActive days! Let\'s make healthy choices today.',
    );

    // ID 101: Evening Warning at 9:00 PM
    NotificationService.scheduleDaily(
      id: 101,
      hour: 21,
      title: '🏃 Keep Your Run Going!',
      body:
          'The day is almost over. Log your dinner to keep your $currentDaysActive-day active record going!',
    );
  }

  // Profile Loader
  Future<void> loadUserProfile(int userId) async {
    currentUserId = userId;
    final data = await ApiService.fetchUserProfile(userId);

    if (data != null) {
      profile = UserProfile(
        firstName: data['firstName'] ?? '',
        lastName: data['lastName'] ?? '',
        email: data['email'] ?? '',
        healthCondition: data['health_condition'] ?? 'None',
        dateOfBirth: data['dateOfBirth'] ?? '',
        height: '${data['height_cm'] ?? 0}',
        currentWeight: '${data['current_weight_kg'] ?? 0}',
        goalWeight: '${data['goal_weight_kg'] ?? 0}',
        activityLevel: data['activity_level'] ?? 'Moderately Active',
        goalCalories: data['goal_calories'] ?? 2000,
        goalSteps: data['goal_steps'] ?? 10000,
      );
      notifyListeners();
      fetchTodaySteps();
    }
  }

  // Dashboard Loader
  Future<void> loadDashboardData(int userId) async {
    bool hasInternet = await isConnectedToInternet();
    if (!hasInternet) return;

    currentUserId = userId;
    final data = await ApiService.fetchTodayDashboard(userId);

    if (data != null) {
      daysActive = data['daysActive'] ?? 0;

      // 🌟 TRIGGER THE DYNAMIC ALARMS
      _scheduleDynamicReminders(daysActive);

      final int dbSteps = data['steps'] ?? 0;
      if (dbSteps > dailySteps) {
        dailySteps = dbSteps;
        _lastSyncedSteps = dbSteps;
      }

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

      if (data['achievements'] != null) {
        achievements = List<String>.from(data['achievements']);
      }
      notifyListeners();
    }
  }

  // =========================================================
  // 🌟 NATIVE HEALTH LOGIC (Catch-Up Pattern)
  // =========================================================

  // Clean up observer if destroyed
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // The lifecycle listener
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      debugPrint("🚀 App Resumed! Catching up on Health Connect data...");
      fetchTodaySteps();
    } else if (state == AppLifecycleState.paused) {
      debugPrint("💤 App went to background. Going to sleep.");
    }
  }

  Future<void> initHealthTracker() async {
    if (_healthInitialized) return;
    _healthInitialized = true;

    // Register to listen to app opens/closes
    WidgetsBinding.instance.addObserver(this);

    // Do one initial fetch
    await fetchTodaySteps();
  }

  Future<void> fetchTodaySteps() async {
    final health = Health();
    var types = [HealthDataType.STEPS, HealthDataType.ACTIVE_ENERGY_BURNED];
    var permissions = [HealthDataAccess.READ, HealthDataAccess.READ];

    if (_isFetchingSteps) return;
    _isFetchingSteps = true;

    try {
      debugPrint("⏱️ Health Polling: Checking the vault...");

      try {
        final status = await health.getHealthConnectSdkStatus();
        if (status != HealthConnectSdkStatus.sdkAvailable) {
          debugPrint("⚠️ Health Connect not available, status: $status");
          await health.installHealthConnect();
          return;
        }
      } catch (e) {
        debugPrint("ℹ️ SDK status check skipped: $e");
      }

      // VIP PASS WRAPPER
      if (!_hasHealthPermissions) {
        bool? alreadyGranted = await health.hasPermissions(
          types,
          permissions: permissions,
        );

        _hasHealthPermissions = await health.requestAuthorization(
          types,
          permissions: permissions,
        );

        if (!_hasHealthPermissions) {
          debugPrint("❌ Health permissions silently denied by OS.");
          if (!_hasShownSettingsDialog && alreadyGranted == false) {
            _hasShownSettingsDialog = true;
            _promptUserToOpenSettings();
          }
          return;
        }
      }

      // ACCESS THE VAULT
      if (_hasHealthPermissions) {
        var now = DateTime.now();
        var midnight = DateTime(now.year, now.month, now.day);

        int? fetchedSteps = await health.getTotalStepsInInterval(midnight, now);

        if (fetchedSteps == null) {
          debugPrint(
            "⚠️ Health Connect returned null. Keeping previous steps.",
          );
          return;
        }

        int steps = fetchedSteps;

        List<HealthDataPoint> calorieData = await health.getHealthDataFromTypes(
          startTime: midnight,
          endTime: now,
          types: [HealthDataType.ACTIVE_ENERGY_BURNED],
        );

        double totalActiveCalories = 0.0;
        for (var point in calorieData) {
          totalActiveCalories += double.tryParse(point.value.toString()) ?? 0.0;
        }

        debugPrint(
          "📊 Health Connect Database says you have: $steps steps today, and burned $totalActiveCalories kcal.",
        );

        dailyActiveCalories = totalActiveCalories.toInt();
        notifyListeners();

        if (steps >= 0 && steps != dailySteps) {
          debugPrint(
            "👟 Updating app steps from $dailySteps to Native OS steps: $steps",
          );

          // SCENARIO 3: CHECK IF THEY JUST HIT THEIR GOAL!
          if (steps >= profile.goalSteps && dailySteps < profile.goalSteps) {
            NotificationService.showInstantNotification(
              id: 300,
              title: '🎉 Step Goal Crashed!',
              body:
                  'Amazing job! You just hit your goal of ${profile.goalSteps} steps.',
            );
          }
          dailySteps = steps;
          notifyListeners();

          bool needsSync = false;

          if (dailySteps - _lastSyncedSteps >= 50) {
            needsSync = true;
          } else if (dailySteps < _lastSyncedSteps) {
            needsSync = true;
          }

          if (currentUserId != null && dailySteps > 0 && needsSync) {
            debugPrint("🔄 Syncing $dailySteps steps to database...");
            List<String> earnedBadges = await ApiService.syncStepsToDatabase(
              userId: currentUserId!,
              steps: dailySteps,
            );

            _lastSyncedSteps = dailySteps;

            if (earnedBadges.isNotEmpty) {
              for (String badgeKey in earnedBadges) {
                _showAchievementPopup(badgeKey);
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint("❌ CRITICAL ERROR with Health Connect: $e");
    } finally {
      _isFetchingSteps = false;
    }
  }

  // =========================================================

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

  Future<void> updateProfile(UserProfile updated) async {
    profile = updated;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? userJson = prefs.getString('saved_user');

      if (userJson != null) {
        Map<String, dynamic> userData = json.decode(userJson);

        userData['firstName'] = updated.firstName;
        userData['lastName'] = updated.lastName;
        userData['email'] = updated.email;
        userData['health_condition'] = updated.healthCondition;
        userData['height_cm'] =
            int.tryParse(updated.height.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
        userData['current_weight_kg'] =
            double.tryParse(
              updated.currentWeight.replaceAll(RegExp(r'[^0-9.]'), ''),
            ) ??
            0.0;
        userData['goal_weight_kg'] =
            double.tryParse(
              updated.goalWeight.replaceAll(RegExp(r'[^0-9.]'), ''),
            ) ??
            0.0;
        userData['goal_calories'] = updated.goalCalories;
        userData['goal_steps'] = updated.goalSteps;
        userData['activity_level'] = updated.activityLevel;

        await prefs.setString('saved_user', json.encode(userData));
        debugPrint("✅ Local 'saved_user' cache updated for next restart!");
      }
    } catch (e) {
      debugPrint("❌ Failed to update local cache: $e");
    }
  }

  void resetState() {
    currentUserId = null;
    dailySteps = 0;
    _lastSyncedSteps = 0;
    daysActive = 0;
    dailyActiveCalories = 0;
    meals.clear();
    workouts.clear();
    profile = UserProfile();
    _healthInitialized = false;
    _hasHealthPermissions = false;
    notifyListeners();
  }

  Future<void> loadWeeklyInsights() async {
    if (currentUserId == null) return;
    isLoadingHistory = true;
    notifyListeners();

    final stats = await ApiService.fetchWeeklyStats(currentUserId!);
    if (stats != null) {
      weeklyDailySummary = stats.dailySummary;
      weeklyMealHistory = stats.meals;
      weeklyWorkoutHistory = stats.workouts;
    }
    isLoadingHistory = false;
    notifyListeners();
  }

  void _showAchievementPopup(String badgeKey) {
    String displayName = badgeKey.replaceAll('_', ' ').toUpperCase();

    // SCENARIO 4: TRIGGER THE INSTANT BADGE NOTIFICATION
    NotificationService.showInstantNotification(
      id: 400,
      title: '🏆 Achievement Unlocked!',
      body: 'You earned the $displayName badge!',
    );

    rootScaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.emoji_events, color: Colors.amber, size: 30),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "ACHIEVEMENT UNLOCKED!",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    "You earned the $displayName badge!",
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green.shade800,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    );
  }

  void _promptUserToOpenSettings() {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Action Required"),
          content: const Text(
            "Aduane Intelligence needs access to your step count to track your daily goals. \n\n"
            "Because permission was previously dismissed, you need to manually allow 'Steps' in your Health Connect settings.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
              child: const Text("Open Settings"),
            ),
          ],
        );
      },
    );
  }
}
