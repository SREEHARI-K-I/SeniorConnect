import "dart:convert";

import "package:http/http.dart" as http;
import "package:shared_preferences/shared_preferences.dart";

class ApiService {
  static const String _apiBaseUrl = String.fromEnvironment(
    "API_BASE_URL",
    defaultValue: "http://10.0.2.2:3000/api",
  );

  static const String _tokenKey = "token";
  static const String _roleKey = "role";
  static const String _nameKey = "name";
  static const String _statusKey = "status";
  static const String _phoneKey = "phone";
  static const String _loggedInKey = "loggedIn";

  static Uri _uri(String path) => Uri.parse("$_apiBaseUrl$path");

  static Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final response = await http.post(
      _uri(path),
      headers: const {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    final Map<String, dynamic> payload = response.body.isNotEmpty
        ? jsonDecode(response.body) as Map<String, dynamic>
        : <String, dynamic>{};

    if (response.statusCode >= 400) {
      throw Exception(
        payload["message"] ?? "Request failed (${response.statusCode})",
      );
    }

    return payload;
  }

  static Future<Map<String, String>> _authorizedJsonHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);

    if (token == null || token.isEmpty) {
      throw Exception("Session expired. Please login again.");
    }

    return {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    };
  }

  static Future<dynamic> _getAuthorized(String path) async {
    final response = await http.get(
      _uri(path),
      headers: await _authorizedJsonHeaders(),
    );

    final dynamic payload = response.body.isNotEmpty
        ? jsonDecode(response.body)
        : <String, dynamic>{};

    if (response.statusCode >= 400) {
      if (payload is Map<String, dynamic>) {
        throw Exception(
          payload["message"] ?? "Request failed (${response.statusCode})",
        );
      }
      throw Exception("Request failed (${response.statusCode})");
    }

    return payload;
  }

  static Future<Map<String, dynamic>> _putAuthorized(String path) async {
    final response = await http.put(
      _uri(path),
      headers: await _authorizedJsonHeaders(),
    );

    final Map<String, dynamic> payload = response.body.isNotEmpty
        ? jsonDecode(response.body) as Map<String, dynamic>
        : <String, dynamic>{};

    if (response.statusCode >= 400) {
      throw Exception(
        payload["message"] ?? "Request failed (${response.statusCode})",
      );
    }

    return payload;
  }

  static Future<Map<String, dynamic>> registerSenior({
    required String name,
    required String phone,
    String? age,
    String? gender,
    String? ward,
    String? panchayat,
    String? houseNumber,
    String? houseName,
    String? pincode,
    String? healthIssues,
    String? occupation,
  }) {
    return _post("/auth/register-senior", {
      "name": name,
      "phone": phone,
      "age": age,
      "gender": gender,
      "ward": ward,
      "panchayat": panchayat,
      "house_number": houseNumber,
      "house_name": houseName,
      "pincode": pincode,
      "health_issues": healthIssues,
      "occupation": occupation,
    });
  }

  static Future<Map<String, dynamic>> registerVolunteer({
    required String name,
    required String phone,
    String? occupation,
  }) {
    return _post("/auth/register-volunteer", {
      "name": name,
      "phone": phone,
      "occupation": occupation,
    });
  }

  static Future<Map<String, dynamic>> verifyRegisterOtp({
    required String phone,
    required String otp,
  }) {
    return _post("/auth/verify-register-otp", {"phone": phone, "otp": otp});
  }

  static Future<Map<String, dynamic>> sendUserLoginOtp({
    required String phone,
  }) {
    return _post("/auth/login/send-otp", {"phone": phone});
  }

  static Future<Map<String, dynamic>> verifyUserLoginOtp({
    required String phone,
    required String otp,
  }) {
    return _post("/auth/login/verify-otp", {"phone": phone, "otp": otp});
  }

  static Future<Map<String, dynamic>> sendAdminLoginOtp({
    required String phone,
    required String password,
  }) {
    return _post("/auth/admin/login/send-otp", {
      "phone": phone,
      "password": password,
    });
  }

  static Future<Map<String, dynamic>> verifyAdminLoginOtp({
    required String phone,
    required String otp,
  }) {
    return _post("/auth/admin/login/verify-otp", {"phone": phone, "otp": otp});
  }

  static Future<void> saveSession({
    required String token,
    required String role,
    required String name,
    required String phone,
    String? status,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_roleKey, role);
    await prefs.setString(_nameKey, name);
    await prefs.setString(_phoneKey, phone);
    if (status != null) {
      await prefs.setString(_statusKey, status);
    } else {
      await prefs.remove(_statusKey);
    }
    await prefs.setBool(_loggedInKey, true);
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_roleKey);
    await prefs.remove(_nameKey);
    await prefs.remove(_statusKey);
    await prefs.remove(_phoneKey);
    await prefs.setBool(_loggedInKey, false);
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_loggedInKey) ?? false;
  }

  static Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_roleKey);
  }

  static Future<Map<String, dynamic>> getAdminStats() async {
    final dynamic response = await _getAuthorized("/admin/stats");
    if (response is! Map<String, dynamic>) {
      throw Exception("Invalid response from server");
    }
    return response;
  }

  static Future<List<Map<String, dynamic>>> getPendingSeniors() async {
    final dynamic response = await _getAuthorized("/admin/pending-seniors");
    if (response is! List) return <Map<String, dynamic>>[];
    return response
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  }

  static Future<List<Map<String, dynamic>>> getPendingVolunteers() async {
    final dynamic response = await _getAuthorized("/admin/pending-volunteers");
    if (response is! List) return <Map<String, dynamic>>[];
    return response
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  }

  static Future<List<Map<String, dynamic>>> getAllVolunteers() async {
    final dynamic response = await _getAuthorized("/admin/volunteers");
    if (response is! List) return <Map<String, dynamic>>[];
    return response
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  }

  static Future<void> approveUser(int userId) async {
    await _putAuthorized("/admin/approve/$userId");
  }

  static Future<void> rejectUser(int userId) async {
    await _putAuthorized("/admin/reject/$userId");
  }
}
