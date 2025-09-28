import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class EventEnrollmentService {
  static String get _baseUrl =>
      dotenv.env['API_BASE_URL']?.trim().replaceAll(RegExp(r"/+$$"), '') ??
      'http://127.0.0.1:8000';

  static Future<String?> _getAccessToken() async {
    const storage = FlutterSecureStorage();
    final tokenJson = await storage.read(key: 'access_token');
    if (tokenJson == null || tokenJson.isEmpty) return null;
    try {
      final data = jsonDecode(tokenJson);
      return data['access_token'] as String?;
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, String>> _authHeaders() async {
    final token = await _getAccessToken();
    final headers = <String, String>{'accept': 'application/json'};
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    headers['content-type'] = 'application/json';
    return headers;
  }

  static Uri _uri(String path) => Uri.parse('$_baseUrl$path');

  static Future<bool> enroll(int eventId) async {
    final res = await http.post(
      _uri('/api/event-enrollments/enroll'),
      headers: await _authHeaders(),
      body: jsonEncode({'event_id': eventId}),
    );
    if (res.statusCode == 200 || res.statusCode == 201) return true;
    throw Exception('Enroll failed: ${res.statusCode} ${res.body}');
  }

  static Future<bool> cancel(int eventId) async {
    final res = await http.delete(
      _uri('/api/event-enrollments/cancel/$eventId'),
      headers: await _authHeaders(),
    );
    if (res.statusCode == 200) return true;
    throw Exception('Cancel failed: ${res.statusCode} ${res.body}');
  }

  static Future<bool> isEnrolled(int eventId) async {
    // Check from user enrollments
    final res = await http.get(
      _uri('/api/event-enrollments/user'),
      headers: await _authHeaders(),
    );
    if (res.statusCode != 200) return false;
    final List<dynamic> list = jsonDecode(res.body);
    return list.any((e) => (e['event_id'] == eventId));
  }

  static Future<int> getTotalEnrolled(int eventId) async {
    final res = await http.get(
      _uri('/api/event-enrollments/event/$eventId'),
      headers: await _authHeaders(),
    );
    if (res.statusCode != 200) return 0;
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return (data['total_enrolled'] as num?)?.toInt() ?? 0;
  }
}
