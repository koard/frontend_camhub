import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../models/account.dart';
import 'dart:developer';

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

    try {
      final res = await _client.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'accept': 'application/json',
        },
        body: jsonEncode(payload),
      );

      if (res.statusCode >= 200 && res.statusCode < 300) {
        log('Signup success: ${res.statusCode}');
        return true;
      } else {
        log('Signup failed: ${res.statusCode} ${res.body}');
        return false;
      }
    } catch (e, st) {
      log('Exception during signup: $e', stackTrace: st);
      return false;
    }
  }

  String _formatDate(DateTime d) {
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year}-$mm-$dd';
  }
}
