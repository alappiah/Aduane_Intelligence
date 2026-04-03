import 'package:dio/dio.dart';

class ApiService {
  // If using Android Emulator, 10.0.2.2 points to your laptop's localhost.
  static const String baseUrl = 'http://192.168.100.55:8000';
  // static const String baseUrl = 'https://aduane-intelligence-backend.onrender.com';
  // static const String baseUrl = 'http://10.0.2.2:8000';
  //uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload

  // Create a single Dio instance to use across your service
  static final Dio _dio = Dio();

  // =========================================================
  // 🔐 AUTHENTICATION ENDPOINTS
  // =========================================================
  static Future<bool> signupUser({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String healthCondition,
  }) async {
    try {
      final response = await _dio.post(
        '$baseUrl/auth/signup',
        data: {
          'firstName': firstName,
          'lastName': lastName,
          'email': email,
          'password': password,
          'health_condition': healthCondition,
        },
      );
      if (response.statusCode == 200) {
        print("✅ User created successfully!");
        return true;
      }
      return false;
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        print("❌ Email already exists: ${e.response?.data}");
      } else {
        print("❌ Server Error: ${e.message}");
      }
      return false;
    } catch (e) {
      print("❌ Unknown Error: $e");
      return false;
    }
  }

  static Future<Map<String, dynamic>?> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '$baseUrl/auth/login',
        data: {'email': email, 'password': password},
      );
      if (response.statusCode == 200) {
        print(
          "✅ Login successful! Welcome back, ${response.data['firstName']}",
        );
        return response.data;
      }
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        print("❌ Incorrect email or password.");
      } else {
        print("❌ Server Error: ${e.message}");
      }
      return null;
    } catch (e) {
      print("❌ Unknown Error: $e");
      return null;
    }
  }

  static Future<bool> requestPasswordReset(String email) async {
    try {
      final response = await _dio.post(
        '$baseUrl/auth/forgot-password',
        data: {'email': email},
      );
      return response.statusCode == 200;
    } on DioException catch (e) {
      print("Error requesting reset code: ${e.message}");
      throw Exception('Failed to connect to the server.');
    }
  }

  static Future<bool> resetPassword(
    String email,
    String resetCode,
    String newPassword,
  ) async {
    try {
      final response = await _dio.post(
        '$baseUrl/auth/reset-password',
        data: {
          'email': email,
          'reset_code': resetCode,
          'new_password': newPassword,
        },
      );
      return response.statusCode == 200;
    } on DioException catch (e) {
      if (e.response != null && e.response?.data is Map) {
        final errorDetail = e.response?.data['detail'];
        throw Exception(errorDetail ?? 'Failed to reset password');
      }
      print("Error resetting password: ${e.message}");
      throw Exception('Failed to communicate with server');
    }
  }

  static Future<bool> changePassword(
    int userId,
    String currentPassword,
    String newPassword,
  ) async {
    try {
      final response = await _dio.post(
        '/auth/change-password', // Note: we rely on your base URL setup
        data: {
          'user_id': userId,
          'current_password': currentPassword,
          'new_password': newPassword,
        },
      );
      return response.statusCode == 200;
    } on DioException catch (e) {
      if (e.response != null && e.response?.data is Map) {
        final errorDetail = e.response?.data['detail'];
        throw Exception(errorDetail ?? 'Failed to update password');
      }
      throw Exception('Failed to communicate with server');
    }
  }

  // =========================================================
  // 👤 USER DATA & DASHBOARD ENDPOINTS
  // =========================================================

  // 🌟 NEW: FETCH USER PROFILE (Fixes the "Sarah Rivera" bug)
  static Future<Map<String, dynamic>?> fetchUserProfile(int userId) async {
    try {
      final response = await _dio.get('$baseUrl/users/$userId/profile');

      if (response.statusCode == 200) {
        print("✅ User profile fetched successfully!");
        return response.data;
      }
      return null;
    } catch (e) {
      print("❌ Error fetching user profile: $e");
      return null;
    }
  }

  static Future<bool> updateUserProfile({
    required int userId,
    required String firstName,
    required String dateOfBirth,
    required int height,
    required double currentWeight,
    required double goalWeight,
    required int goalCalories,
    required int goalSteps,
    required String activityLevel,
    required String healthCondition,
  }) async {
    try {
      final response = await _dio.put(
        '$baseUrl/users/update/$userId',
        data: {
          'firstName': firstName,
          'date_of_birth': dateOfBirth,
          'height_cm': height,
          'current_weight_kg': currentWeight,
          'goal_weight_kg': goalWeight,
          'goal_calories': goalCalories,
          'goal_steps': goalSteps,
          'activity_level': activityLevel,
          'health_condition': healthCondition,
        },
      );
      if (response.statusCode == 200) {
        print("✅ Profile updated successfully in database!");
        return true;
      }
      return false;
    } catch (e) {
      print("❌ Error updating profile: $e");
      return false;
    }
  }

  static Future<Map<String, dynamic>?> fetchTodayDashboard(int userId) async {
    try {
      final response = await _dio.get('$baseUrl/users/$userId/dashboard/today');
      if (response.statusCode == 200) {
        print("✅ Dashboard data fetched successfully!");
        return response.data;
      }
      return null;
    } catch (e) {
      print("❌ Error fetching dashboard data: $e");
      return null;
    }
  }

  static Future<bool> logMeal({
    required int userId,
    required String name,
    required String mealType,
    required int calories,
    required int carbs,
    required int protein,
    required int fats,
    required int sodium,
    required int sugar,
    required String time,
  }) async {
    try {
      final response = await _dio.post(
        '$baseUrl/users/meals/log',
        data: {
          'user_id': userId,
          'name': name,
          'mealType': mealType,
          'calories': calories,
          'carbs': carbs,
          'protein': protein,
          'fats': fats,
          'sodium': sodium,
          'sugar': sugar,
          'time': time,
        },
      );
      if (response.statusCode == 200) {
        print("✅ Meal logged successfully to database!");
        return true;
      }
      return false;
    } catch (e) {
      print("❌ Error logging meal: $e");
      return false;
    }
  }

  static Future<bool> logWorkout({
    required int userId,
    required String name,
    required String type,
    required int durationMinutes,
    required int caloriesBurned,
    required String time,
  }) async {
    try {
      final response = await _dio.post(
        '$baseUrl/users/workouts/log',
        data: {
          'user_id': userId,
          'name': name,
          'type': type,
          'durationMinutes': durationMinutes,
          'caloriesBurned': caloriesBurned,
          'time': time,
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        print("✅ Workout successfully saved to the database!");
        return true;
      }
      return false;
    } catch (e) {
      print("❌ Error logging workout to server: $e");
      return false;
    }
  }

  static Future<bool> syncStepsToDatabase({
    required int userId,
    required int steps,
  }) async {
    try {
      final today = DateTime.now();
      final dateString =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      final response = await _dio.post(
        '$baseUrl/users/steps/sync',
        data: {'user_id': userId, 'date': dateString, 'steps': steps},
      );
      if (response.statusCode == 200) {
        print("✅ Steps silently synced to database: $steps");
        return true;
      }
      return false;
    } catch (e) {
      print("❌ Error syncing steps: $e");
      return false;
    }
  }

  // =========================================================
  // 💬 CHAT & AI ENDPOINTS
  // =========================================================
  static Future<List<dynamic>> getChatHistory(int userId) async {
    try {
      final response = await _dio.get('$baseUrl/chat/history/$userId');
      return response.data;
    } catch (e) {
      print("❌ Error fetching history: $e");
      return [];
    }
  }

  static Future<int?> saveChatMessage(
    int userId,
    String text,
    String sender, {
    List? recipes,
  }) async {
    try {
      final response = await _dio.post(
        '$baseUrl/chat/save/$userId',
        data: {"content": text, "sender": sender, "recipes": recipes ?? []},
      );
      return response.data['id'];
    } catch (e) {
      print("Error saving message: $e");
      return null;
    }
  }

  static Future<void> updateChatMessage(
    int messageId,
    String content, {
    List? recipes,
  }) async {
    try {
      await _dio.put(
        '$baseUrl/chat/update/$messageId',
        data: {"content": content, "recipes": recipes ?? []},
      );
      print("✅ In-place update successful for ID: $messageId");
    } catch (e) {
      print("🚨 Error updating message $messageId: $e");
    }
  }

  static Future<bool> deleteChatHistory(int userId) async {
    try {
      final response = await _dio.delete('$baseUrl/chat/history/$userId');
      return response.statusCode == 200;
    } catch (e) {
      print("🚨 Error deleting history: $e");
      return false;
    }
  }
}
