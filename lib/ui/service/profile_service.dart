import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class UserService {
  String get _baseUrl =>
      dotenv.env['API_BASE_URL']?.trim().replaceAll(RegExp(r"/+$"), '') ??
      'http://localhost:8000';

  Future<Map<String, dynamic>?> getUserProfile() async {
    final storage = FlutterSecureStorage();
    final token = await storage.read(key: 'access_token');
    log('Access token from storage: $token');

    if (token == null || token.isEmpty) {
      log('No access_token in storage');
      return null;
    }

    final data = jsonDecode(token);
    final accessToken = data['access_token'];

    final uri = Uri.parse('$_baseUrl/api/user');
    final res = await http.get(
      uri,
      headers: {
        'accept': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
    );
    log('Profile response status: ${res.statusCode}');

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final data = jsonDecode(res.body);
      if (data is Map<String, dynamic>) return data;
      log('Profile response is not a JSON object');
      return null;
    }

    if (res.statusCode == 401) {
      await storage.delete(key: 'access_token');
    }
    return null;
  }
}
