import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../models/account.dart';
import 'dart:async';
import 'dart:developer';

class ApiException implements Exception {
  final int statusCode;
  final String body;
  final String? detail;
  ApiException(this.statusCode, this.body, {this.detail});
  @override
  String toString() => detail ?? body;
}

class UserService {
  UserService({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;

  String get _baseUrl =>
      dotenv.env['API_BASE_URL']?.trim().replaceAll(RegExp(r"/+$"), '') ??
      'http://localhost:8000';

  Future<bool> signup(
    User userModel, {
    required String username,
    required DateTime birthDate,
    int? facultyId,
    int roleId = 2,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/auth/signup');
    final payload = {
      'username': username,
      'email': userModel.email,
      'password': userModel.password,
      'first_name': userModel.firstName,
      'last_name': userModel.lastName,
      'birth_date': _formatDate(birthDate),
      'faculty_id': facultyId,
      'year_of_study': 1,
      'role_id': 2,
    };

    final res = await _client
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'accept': 'application/json',
          },
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 15));

    if (res.statusCode >= 200 && res.statusCode < 300) {
      log('Signup success: ${res.statusCode}');
      return true;
    }

    // parse detail
    String? detail;
    try {
      final parsed = jsonDecode(res.body);
      if (parsed is Map && parsed['detail'] != null) {
        detail = parsed['detail'].toString();
      }
    } catch (_) {}

    throw ApiException(res.statusCode, res.body, detail: detail);
  }

  Future<bool> login(String email, String password) async {
    final storage = FlutterSecureStorage();
    final uri = Uri.parse('$_baseUrl/api/auth/signin');
    final payload = {'email': email, 'password': password};

    final res = await _client
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'accept': 'application/json',
          },
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 15));

    if (res.statusCode >= 200 && res.statusCode < 300) {
      await storage.write(key: "access_token", value: res.body);
      log("Access token: ${await storage.read(key: "access_token")}");
      log('Login success: ${res.statusCode}');
      return true;
    }

    String? detail;
    try {
      final parsed = jsonDecode(res.body);
      if (parsed is Map && parsed['detail'] != null) {
        detail = parsed['detail'].toString();
      }
    } catch (_) {}
    throw ApiException(res.statusCode, res.body, detail: detail);
  }

  String _formatDate(DateTime d) {
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year}-$mm-$dd';
  }
}
