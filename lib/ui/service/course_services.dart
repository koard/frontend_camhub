import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:developer';
import 'dart:convert';
import 'package:http/http.dart' as http;

class CourseService {
  String get _baseUrl =>
      dotenv.env['API_BASE_URL']?.trim().replaceAll(RegExp(r"/+$"), '') ??
      'http://localhost:8000';

  Future<Map<String, dynamic>?> getCourses() async {
    final storage = FlutterSecureStorage();
    final token = await storage.read(key: 'access_token');
    final uri = Uri.parse('$_baseUrl/api/enrollments/me');

    final res = await http.get(
      uri,
      headers: {'accept': 'application/json', 'Authorization': 'Bearer $token'},
    );
    log('Courses response status: ${res.statusCode}');

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      log('Failed to fetch announcements: ${res.statusCode}');
      return null;
    }
  }
}
