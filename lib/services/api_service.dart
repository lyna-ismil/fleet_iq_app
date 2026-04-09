import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../constants/api_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/car.dart';
import '../models/booking_model.dart';
import '../models/user_model.dart';
import '../models/notification_model.dart';

class UnauthorizedException implements Exception {
  final String message;
  UnauthorizedException([this.message = "Unauthorized access"]);
}

class PriceEstimate {
  final double basePrice;
  final double seasonAdjustment;
  final double superCdw;
  final double additionalDriver;
  final double youngDriverSurcharge;
  final double adminFee;
  final double vat;
  final double total;

  PriceEstimate({
    required this.basePrice,
    required this.seasonAdjustment,
    required this.superCdw,
    required this.additionalDriver,
    required this.youngDriverSurcharge,
    required this.adminFee,
    required this.vat,
    required this.total,
  });

  factory PriceEstimate.fromJson(Map<String, dynamic> json) {
    return PriceEstimate(
      basePrice: (json['baseRental'] ?? 0).toDouble(),
      seasonAdjustment: (json['seasonAdjustment'] ?? 0).toDouble(),
      superCdw: (json['superCdw'] ?? 0).toDouble(),
      additionalDriver: (json['additionalDriver'] ?? 0).toDouble(),
      youngDriverSurcharge: (json['youngDriverSurcharge'] ?? 0).toDouble(),
      adminFee: (json['adminFee'] ?? 0).toDouble(),
      vat: (json['vat'] ?? 0).toDouble(),
      total: (json['total'] ?? 0).toDouble(),
    );
  }
}

class EstimateRequest {
  final String vehicleName;
  final DateTime pickupDate;
  final DateTime dropoffDate;
  final String location;
  final String driverAgeGroup;
  final bool superCdw;
  final bool additionalDriver;

  EstimateRequest({
    required this.vehicleName,
    required this.pickupDate,
    required this.dropoffDate,
    required this.location,
    required this.driverAgeGroup,
    required this.superCdw,
    required this.additionalDriver,
  });

  Map<String, dynamic> toJson() => {
    'vehicleName': vehicleName,
    'pickupDate': pickupDate.toIso8601String(),
    'dropoffDate': dropoffDate.toIso8601String(),
    'location': location,
    'driverAgeGroup': driverAgeGroup,
    'superCdw': superCdw,
    'additionalDriver': additionalDriver,
  };
}

class BookingRequest {
  final String userId;
  final String carId;
  final DateTime startDate;
  final DateTime endDate;
  final String pickupLocation;
  final String dropoffLocation;

  BookingRequest({
    required this.userId,
    required this.carId,
    required this.startDate,
    required this.endDate,
    required this.pickupLocation,
    required this.dropoffLocation,
  });

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'carId': carId,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate.toIso8601String(),
    'pickupLocation': pickupLocation,
    'dropoffLocation': dropoffLocation,
  };
}

class ApiService {
  static Future<String?> _getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString("accessToken");
  }

  static Future<bool> _refreshToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? refreshToken = prefs.getString("refreshToken");
    if (refreshToken == null) return false;
    // For now, no refresh endpoint is implemented in backend, just fallback
    return false;
  }

  static Future<http.Response> _send(String method, String url, String? token, Map<String, dynamic>? body) async {
    final uri = Uri.parse(url);
    final headers = {
      "Content-Type": "application/json",
      if (token != null) "Authorization": "Bearer $token",
    };
    
    switch(method.toUpperCase()) {
      case 'POST': return await http.post(uri, headers: headers, body: body != null ? jsonEncode(body) : null);
      case 'PUT': return await http.put(uri, headers: headers, body: body != null ? jsonEncode(body) : null);
      case 'DELETE': return await http.delete(uri, headers: headers);
      case 'GET':
      default: return await http.get(uri, headers: headers);
    }
  }

  static Future<http.Response> _request(
    String method, String url, {Map<String, dynamic>? body}
  ) async {
    String? token = await _getToken();
    var response = await _send(method, url, token, body);

    if (response.statusCode == 401) {
      final refreshed = await _refreshToken();
      if (refreshed) {
        token = await _getToken();
        response = await _send(method, url, token, body);
      } else {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.remove("accessToken");
        await prefs.remove("userId");
        throw UnauthorizedException();
      }
    }
    return response;
  }

  static Future<Map<String, String>> _getHeaders([bool isMultipart = false, String? token]) async {
    String? authToken = token ?? await _getToken();
    Map<String, String> headers = {};
    if (!isMultipart) headers["Content-Type"] = "application/json";
    if (authToken != null) headers["Authorization"] = "Bearer $authToken";
    return headers;
  }

  static Map<String, dynamic> _decodeJwt(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) throw Exception('Invalid token');
      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final resp = utf8.decode(base64Url.decode(normalized));
      return jsonDecode(resp);
    } catch (e) {
      return {};
    }
  }

  // Auth
  static Future<Map<String, dynamic>> loginUser(String email, String password) async {
    final response = await _request('POST', '$authEndpoint/user/login', body: {
      "email": email,
      "password": password,
    });
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      String accessToken = data["accessToken"];
      var decoded = _decodeJwt(accessToken);
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString("accessToken", accessToken);
      if (decoded["id"] != null) await prefs.setString("userId", decoded["id"]);
      return data;
    } else {
      throw Exception("Login Failed: ${response.body}");
    }
  }

  static Future<Map<String, dynamic>> resetPassword(String email) async {
    final response = await _request('POST', '$userEndpoint/forgot-password', body: {"email": email});
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to send password reset link.");
    }
  }

  // Cars
  static Future<List<Car>> getPairedCars() async {
    final response = await _request('GET', '$carEndpoint?paired=true');
    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((c) => Car.fromJson(c)).toList();
    } else {
      throw Exception("Failed to fetch paired cars: ${response.body}");
    }
  }

  static Future<Car> getCarById(String id) async {
    final response = await _request('GET', '$carEndpoint/$id');
    if (response.statusCode == 200) {
      return Car.fromJson(jsonDecode(response.body));
    } else {
      throw Exception("Failed to fetch car by id.");
    }
  }
  
  static Future<List<Map<String, dynamic>>> getAvailableCars() async {
    final response = await _request('GET', '$carEndpoint?status=AVAILABLE');
    if (response.statusCode == 200) {
      final List<dynamic> carList = jsonDecode(response.body);
      return carList.map((car) => car as Map<String, dynamic>).toList();
    } else {
      throw Exception("Failed to fetch available cars: ${response.body}");
    }
  }

  static Future<List<Map<String, dynamic>>> getPairedAvailableCars() async {
    final response = await _request('GET', '$carEndpoint?paired=true');
    if (response.statusCode == 200) {
      final List<dynamic> carList = jsonDecode(response.body);
      return carList.map((car) => car as Map<String, dynamic>).toList();
    } else {
      throw Exception("Failed to fetch paired available cars: ${response.body}");
    }
  }

  // Bookings
  static Future<Map<String, dynamic>> getMyBookings(String userId) async {
    final response = await _request('GET', '$bookingEndpoint/my-bookings?userId=$userId');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to fetch my bookings: ${response.body}");
    }
  }

  static Future<BookingModel> createBooking(BookingRequest req) async {
    final response = await _request('POST', bookingEndpoint, body: req.toJson());
    if (response.statusCode == 201) {
      return BookingModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception("Booking Error: ${response.body}");
    }
  }

  static Future<String> generateNfcKey(String bookingId) async {
    final response = await _request('POST', '$bookingEndpoint/$bookingId/generate-key');
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['nfcKey'] ?? jsonDecode(response.body)['key'] ?? '';
    } else {
      throw Exception("NFC Key generation failed: ${response.body}");
    }
  }

  static Future<String> getContractUrl(String bookingId) async {
    final response = await _request('GET', '$bookingEndpoint/$bookingId/contract');
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['contractUrl'] ?? '';
    } else {
      throw Exception("Failed to get contract url");
    }
  }

  // Pricing
  static Future<PriceEstimate> estimatePrice(EstimateRequest req) async {
    final url = '$pricingVehiclesEndpoint/estimate';
    final response = await http.post(Uri.parse(url), headers: {
      "Content-Type": "application/json"
    }, body: jsonEncode(req.toJson()));
    if (response.statusCode == 200) {
      return PriceEstimate.fromJson(jsonDecode(response.body));
    } else {
      throw Exception("Price Estimation failed: ${response.body}");
    }
  }

  static Future<List<String>> getPricingLocations() async {
    final response = await _request('GET', '$pricingVehiclesEndpoint/locations');
    if (response.statusCode == 200) {
      return List<String>.from(jsonDecode(response.body));
    }
    return [];
  }

  static Future<Map<String, dynamic>?> getVehicleByMarque(String marque) async {
    final normalized = marque.trim();
    final url = '$pricingVehiclesEndpoint/by-marque?marque=${Uri.encodeComponent(normalized)}';
    final response = await _request('GET', url);
    if (response.statusCode == 200) return jsonDecode(response.body);
    return null;
  }

  // Notifications
  static Future<List<NotificationModel>> getNotifications(String userId) async {
    final response = await _request('GET', '$notificationEndpoint?userId=$userId');
    if (response.statusCode == 200) {
      final List<dynamic> items = jsonDecode(response.body)['notifications'] ?? jsonDecode(response.body) ?? [];
      return items.map((n) => NotificationModel.fromJson(n)).toList();
    }
    return [];
  }

  static Future<void> markNotificationRead(String notificationId) async {
    final response = await _request('PUT', '$notificationEndpoint/$notificationId/read');
    if (response.statusCode != 200) {
      throw Exception("Failed to mark as read");
    }
  }

  static Future<bool> deleteNotification(String notificationId) async {
    final response = await _request('DELETE', '$notificationEndpoint/$notificationId');
    return response.statusCode == 200;
  }

  // User / KYC
  static Future<UserModel> getProfile(String userId) async {
    final response = await _request('GET', '$userEndpoint/$userId');
    if (response.statusCode == 200) {
      return UserModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception("Failed to fetch user profile.");
    }
  }

  static Future<Map<String, dynamic>> getUserProfile(String userId) async {
    final response = await _request('GET', '$userEndpoint/$userId');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to fetch user profile.");
    }
  }

  static Future<List<dynamic>> getAllUsers() async {
    final response = await _request('GET', userEndpoint);
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception("Failed to fetch users");
  }

  static Future<Map<String, dynamic>> updateUser(String userId, String numPhone, String email, String profilePicture) async {
    final response = await _request('PUT', '$userEndpoint/$userId', body: {
      "phone": numPhone,
      "email": email,
      "profilePhoto": profilePicture,
    });
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception("Update Failed: ${response.body}");
  }

  static Future<void> uploadKycDocuments(String userId, File? cin, File? license) async {
    final url = Uri.parse('$userEndpoint/$userId/kyc');
    var request = http.MultipartRequest('PUT', url);
    request.headers.addAll(await _getHeaders(true));
    if (cin != null) request.files.add(await http.MultipartFile.fromPath('cinImage', cin.path));
    if (license != null) request.files.add(await http.MultipartFile.fromPath('licenseImage', license.path));
    
    var res = await request.send();
    if (res.statusCode != 200) {
      throw Exception("Failed to upload KYC");
    }
  }

  // Reclamation
  static Future<Map<String, dynamic>> submitReclamation(String userId, String title, String description, File? image) async {
    final url = Uri.parse(reclamationEndpoint);
    var request = http.MultipartRequest('POST', url);
    request.headers.addAll(await _getHeaders(true));
    
    request.fields['userId'] = userId;
    request.fields['title'] = title;
    request.fields['message'] = description;

    if (image != null) {
      request.files.add(await http.MultipartFile.fromPath('image', image.path));
    }
    var res = await request.send();
    var resStr = await res.stream.bytesToString();
    if (res.statusCode == 201) return jsonDecode(resStr);
    throw Exception("Failed to submit reclamation: $resStr");
  }
}
