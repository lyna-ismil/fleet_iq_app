import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../constants/api_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static Future<Map<String, dynamic>> signupUser(String cin, String permis,
      String numPhone, String email, String password) async {
    final url = Uri.parse('$userEndpoint/signup');

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "cin": cin,
        "permis": permis,
        "num_phone": numPhone,
        "email": email,
        "password": password,
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Signup Failed: ${response.body}");
    }
  }

  static Future<Map<String, dynamic>> loginUser(
      String email, String password) async {
    final url = Uri.parse('$userEndpoint/login');

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

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString("userId", data["user"]["_id"]);

      return data;
    } else {
      throw Exception("Login Failed: ${response.body}");
    }
  }

  static Future<bool> createBooking({
    required String userId,
    required String carId,
    required DateTime startDate,
    required DateTime endDate,
    required String locationBeforeRenting,
    required String locationAfterRenting,
    required String estimatedLocation,
  }) async {
    final url = Uri.parse(bookingEndpoint);

    final String idBooking = DateTime.now().millisecondsSinceEpoch.toString();

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "id_booking": idBooking,
        "id_user": userId,
        "id_car": carId,
        "date_hour_booking": startDate.toIso8601String(),
        "date_hour_expire": endDate.toIso8601String(),
        "location_Before_Renting": locationBeforeRenting,
        "location_After_Renting": locationAfterRenting,
        "estimated_Location": estimatedLocation,
        "status": false,
        "paiement": 0,
      }),
    );

    if (response.statusCode == 201) {
      return true;
    } else {
      print("❌ Booking Error: ${response.body}");
      return false;
    }
  }

  static Future<List<dynamic>> getAllUsers() async {
    final url = Uri.parse(userEndpoint);

    final response = await http.get(
      url,
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to fetch users");
    }
  }

  static Future<List<Map<String, dynamic>>> getAvailableCars() async {
    try {
      final url = Uri.parse('$carEndpoint?car_work=true');

      final response = await http.get(
        url,
        headers: {"Content-Type": "application/json"},
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
      headers: {"Content-Type": "application/json"},
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
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "num_phone": numPhone,
        "email": email,
        "profile_picture": profilePicture,
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
      headers: {"Content-Type": "application/json"},
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
    request.fields['id_user'] = userId;
    request.fields['title'] = title;
    request.fields['description'] = description;

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
