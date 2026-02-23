import 'package:dio/dio.dart';

class ApiService {
  // If using Android Emulator, 10.0.2.2 points to your laptop's localhost.
  static const String baseUrl = 'http://192.168.100.79:8000';

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
  static Future<void> saveChatMessage(
    int userId,
    String content,
    String sender,
  ) async {
    try {
      await _dio.post(
        '$baseUrl/chat/save/$userId',
        data: {'content': content, 'sender': sender},
      );
    } catch (e) {
      print("❌ Error saving message: $e");
    }
  }
}
