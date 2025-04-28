import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl;

  ApiService({this.baseUrl = 'http://10.0.2.2:5000'});

  // Register a new user and auto-login
  Future<Map<String, dynamic>> registerUser({
    required String email,
    required String password,
    int? age,
    String? gender,
    double? height,
    double? weight,
    double? bodyFat,
    String? existingConditions,
    String? allergies,
    String? medications,
    String? dietType,
    String? mealPattern,
    double? waterIntake,
    String? sugarSaltIntake,
    String? activityLevel,
    String? preferredExercises,
    int? workoutDuration,
    String? primaryGoal,
    double? targetWeight,
    String? timeframe,
    double? sleepDuration,
    String? stressLevel,
    String? smokingAlcohol,
  }) async {
    // Updated URL for registration
    final url = Uri.parse('$baseUrl/api/register');
    final Map<String, dynamic> data = {
      "email": email,
      "password": password,
      "age": age,
      "gender": gender,
      "height": height,
      "weight": weight,
      "body_fat": bodyFat,
      "existing_conditions": existingConditions,
      "allergies": allergies,
      "medications": medications,
      "diet_type": dietType,
      "meal_pattern": mealPattern,
      "water_intake": waterIntake,
      "sugar_salt_intake": sugarSaltIntake,
      "activity_level": activityLevel,
      "preferred_exercises": preferredExercises,
      "workout_duration": workoutDuration,
      "primary_goal": primaryGoal,
      "target_weight": targetWeight,
      "timeframe": timeframe,
      "sleep_duration": sleepDuration,
      "stress_level": stressLevel,
      "smoking_alcohol": smokingAlcohol,
    };

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to register user: ${response.body}');
    }
  }

  // Login using email and password
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl/api/login');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to login: ${response.body}');
    }
  }

  // Retrieve user details by user ID
  Future<Map<String, dynamic>> getUser(int userId) async {
    final url = Uri.parse('$baseUrl/api/user/$userId');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get user: ${response.body}');
    }
  }

  // Update user details by user ID
  Future<Map<String, dynamic>> updateUser(
      int userId, Map<String, dynamic> updatedData) async {
    final url = Uri.parse('$baseUrl/api/user/$userId');
    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(updatedData),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to update user: ${response.body}');
    }
  }

  // Delete user by user ID
  Future<Map<String, dynamic>> deleteUser(int userId) async {
    final url = Uri.parse('$baseUrl/api/user/$userId');
    final response = await http.delete(url);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to delete user: ${response.body}');
    }
  }

Future<Map<String, dynamic>> askAiWithPicture({
  required int userId,
  required String question,
  required String image,
  Duration timeout = const Duration(seconds: 180),
}) async {
  final url = Uri.parse('$baseUrl/api/ask_with_picture/$userId');
  try {
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'question': question,
        'image_base64': image  // Changed from 'image' to 'image_base64'
      }),
    ).timeout(timeout);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Server returned ${response.statusCode}: ${response.body}');
    }
  } on TimeoutException {
    throw Exception('Request timed out. Please try again later.');
  }
}
  // Ask AI based on stored user data by user ID
  Future<Map<String, dynamic>> askAi({
    required int userId,
    required String question,
    Duration timeout = const Duration(seconds: 180),
  }) async {
    final url = Uri.parse('$baseUrl/api/ask/$userId');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'question': question}),
      ).timeout(timeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Server returned ${response.statusCode}: ${response.body}');
      }
    } on TimeoutException {
      throw   Exception('Request timed out. Please try again later.');
    }
  }
}
