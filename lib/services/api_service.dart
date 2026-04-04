import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../constants/api_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static Future<Map<String, String>> _getHeaders([bool isMultipart = false]) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("accessToken");

    Map<String, String> headers = {};
    if (!isMultipart) {
      headers["Content-Type"] = "application/json";
    }
    if (token != null) {
      headers["Authorization"] = "Bearer $token";
    }
    return headers;
  }

  static Map<String, dynamic> _decodeJwt(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        throw Exception('Invalid token');
      }

      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final resp = utf8.decode(base64Url.decode(normalized));
      return jsonDecode(resp);
    } catch (e) {
      return {};
    }
  }

  static Future<Map<String, dynamic>> loginUser(
      String email, String password) async {
    final url = Uri.parse('$authEndpoint/user/login');

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": email,
        "password": password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      String accessToken = data["accessToken"];
      var decoded = _decodeJwt(accessToken);

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString("accessToken", accessToken);
      
      if (decoded["id"] != null) {
        await prefs.setString("userId", decoded["id"]);
      }

      return data;
    } else {
      throw Exception("Login Failed: ${response.body}");
    }
  }

  static Future<Map<String, dynamic>?> createBooking({
    required String userId,
    required String carId,
    required DateTime startDate,
    required DateTime endDate,
    required String locationBeforeRenting,
    required String locationAfterRenting,
    required String estimatedLocation,
  }) async {
    final url = Uri.parse(bookingEndpoint);
    
    final response = await http.post(
      url,
      headers: await _getHeaders(),
      body: jsonEncode({
        "userId": userId,
        "carId": carId,
        "startDate": startDate.toIso8601String(),
        "endDate": endDate.toIso8601String(),
        "pickupLocation": locationBeforeRenting,
        "dropoffLocation": locationAfterRenting,
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      print("❌ Booking Error: ${response.body}");
      return null;
    }
  }

  static Future<List<dynamic>> getAllUsers() async {
    final url = Uri.parse(userEndpoint);

    final response = await http.get(
      url,
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to fetch users");
    }
  }

  static Future<List<Map<String, dynamic>>> getAvailableCars() async {
    try {
      final url = Uri.parse('$carEndpoint?status=AVAILABLE');

      final response = await http.get(
        url,
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> carList = jsonDecode(response.body);
        return carList.map((car) => car as Map<String, dynamic>).toList();
      } else {
        throw Exception("Failed to fetch available cars: ${response.body}");
      }
    } catch (e) {
      print('❌ Error fetching available cars: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> getUserProfile(String userId) async {
    final url = Uri.parse('$userEndpoint/$userId');

    final response = await http.get(
      url,
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to fetch user profile.");
    }
  }

  static Future<Map<String, dynamic>> updateUser(String userId, String numPhone,
      String email, String profilePicture) async {
    final url = Uri.parse('$userEndpoint/$userId');

    final response = await http.put(
      url,
      headers: await _getHeaders(),
      body: jsonEncode({
        "phone": numPhone,
        "email": email,
        "profilePhoto": profilePicture,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Update Failed: ${response.body}");
    }
  }

  static Future<Map<String, dynamic>> resetPassword(String email) async {
    final url = Uri.parse('$userEndpoint/forgot-password');

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to send password reset link.");
    }
  }

  static Future<List<dynamic>> getAllCars() async {
    final url = Uri.parse(carEndpoint);

    final response = await http.get(
      url,
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to fetch cars: ${response.body}");
    }
  }

  static Future<Map<String, dynamic>> submitReclamation(
      String userId, String title, String description, File? image) async {
    final url = Uri.parse('$reclamationEndpoint');

    var request = http.MultipartRequest('POST', url);
    request.headers.addAll(await _getHeaders(true));
    
    request.fields['userId'] = userId;
    request.fields['title'] = title;
    request.fields['message'] = description;

    if (image != null) {
      request.files.add(await http.MultipartFile.fromPath('image', image.path));
    }

    var response = await request.send();
    var responseData = await response.stream.bytesToString();

    if (response.statusCode == 201) {
      return jsonDecode(responseData);
    } else {
      throw Exception("Failed to submit reclamation: $responseData");
    }
  }
}
