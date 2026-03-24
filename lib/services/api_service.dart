import 'package:dio/dio.dart';

class ApiService {
  // If using Android Emulator, 10.0.2.2 points to your laptop's localhost.
  // static const String baseUrl = 'http://192.168.100.79:8000';?\
  static const String baseUrl = 'http://192.168.100.55:8000';
  // static const String baseUrl = 'http://10.0.2.2:8000';

  //uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
  // Create a single Dio instance to use across your service
  static final Dio _dio = Dio();

  // --- SIGNUP FUNCTION ---
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
      } else {
        return false;
      }
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

  // --- LOGIN FUNCTION ---
  static Future<Map<String, dynamic>?> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '$baseUrl/auth/login', // Update this to '$baseUrl/auth/login' if you are using the APIRouter prefix we discussed earlier!
        data: {'email': email, 'password': password},
      );

      if (response.statusCode == 200) {
        print(
          "✅ Login successful! Welcome back, ${response.data['firstName']}",
        );
        return response.data; // <-- RETURN THE ACTUAL USER DATA MAP
      } else {
        return null; // Return null if it fails
      }
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

  // --- FETCH CHAT HISTORY ---
  static Future<List<dynamic>> getChatHistory(int userId) async {
    try {
      final response = await _dio.get('$baseUrl/chat/history/$userId');
      return response.data; // List of message objects
    } catch (e) {
      print("❌ Error fetching history: $e");
      return [];
    }
  }

  // --- SAVE MESSAGE TO DB ---
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
      // Return the ID that PostgreSQL just generated!
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
      // Uses the new PUT /update/{id} endpoint
      final response = await _dio.put(
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

  static Future<bool> requestPasswordReset(String email) async {
    try {
      // Dio automatically encodes the 'data' map to JSON!
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

      return response.statusCode == 200; // Success!
    } on DioException catch (e) {
      // 🌟 Dio throws an exception for 400/500 errors.
      // We grab your FastAPI 'detail' message from the error response!
      if (e.response != null && e.response?.data is Map) {
        final errorDetail = e.response?.data['detail'];
        throw Exception(errorDetail ?? 'Failed to reset password');
      }

      print("Error resetting password: ${e.message}");
      throw Exception('Failed to communicate with server');
    }
  }

  // --- UPDATE USER PROFILE ---
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
    required String healthCondition, // 🌟 1. Added the new parameter here!
  }) async {
    try {
      final response = await _dio.put(
        '$baseUrl/auth/users/update/$userId', // We will build this FastAPI route next!
        data: {
          'firstName': firstName,
          'date_of_birth': dateOfBirth,
          'height_cm': height,
          'current_weight_kg': currentWeight,
          'goal_weight_kg': goalWeight,
          'goal_calories': goalCalories,
          'goal_steps': goalSteps,
          'activity_level': activityLevel,
          'health_condition': healthCondition, // 🌟 2. Added to the payload here!
        },
      );

      if (response.statusCode == 200) {
        print("✅ Profile updated successfully in database!");
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print("❌ Error updating profile: $e");
      return false;
    }
  }
}
