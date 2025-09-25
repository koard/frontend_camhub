import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:developer';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/course.dart';

class CourseService {
  String get _baseUrl =>
      dotenv.env['API_BASE_URL']?.trim().replaceAll(RegExp(r"/+$$"), '') ??
      'http://localhost:8000';

  /// Fetch list of courses from API
  /// Returns an empty list on 204, throws on non-2xx errors.
  Future<List<Course>> getCourses() async {
    try {
      final storage = const FlutterSecureStorage();
      final tokenJson = await storage.read(key: 'access_token');
      String? bearer;
      if (tokenJson != null) {
        try {
          final data = jsonDecode(tokenJson);
          bearer = data['access_token']?.toString();
        } catch (_) {}
      }

      final uri = Uri.parse('$_baseUrl/api/courses');
      final headers = <String, String>{'accept': 'application/json'};
      if (bearer != null && bearer.isNotEmpty) {
        headers['Authorization'] = 'Bearer $bearer';
      }

      final res = await http.get(uri, headers: headers);
      log('GET /api/courses -> ${res.statusCode}');
      if (res.statusCode >= 200 && res.statusCode < 300) {
        if (res.body.isEmpty) return <Course>[];
        final decoded = jsonDecode(res.body);
        if (decoded is List) {
          return decoded.map((e) => Course.fromJson(e)).toList();
        } else {
          throw Exception('Unexpected response shape for /api/courses');
        }
      }
      throw Exception('Failed to fetch courses: HTTP ${res.statusCode}');
    } catch (e) {
      log('Error in CourseService.getCourses: $e');
      rethrow;
    }
  }
}
