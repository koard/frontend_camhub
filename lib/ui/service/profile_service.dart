import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
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

  Future<bool> uploadProfileImage(
    File imageFile, {
    MediaType? contentType,
  }) async {
    final storage = FlutterSecureStorage();
    final token = await storage.read(key: 'access_token');

    if (token == null || token.isEmpty) {
      log('No access_token in storage');
      return false;
    }
    log('Access token from storage: $token');

    try {
      final data = jsonDecode(token);
      final accessToken = data['access_token'];

      final uri = Uri.parse('$_baseUrl/api/user/upload-profile-image');
      final request = http.MultipartRequest('POST', uri);

      request.headers.addAll({
        'accept': 'application/json',
        'Authorization': 'Bearer $accessToken',
      });

      final multipartFile = await http.MultipartFile.fromPath(
        'file',
        imageFile.path,
        filename: imageFile.path.split('/').last,
        contentType: contentType,
      );
      request.files.add(multipartFile);
      log('Uploading file: ${imageFile.path}');

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      log('Upload response status: ${response.statusCode}');
      log('Upload response body: $responseBody');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return true;
      }

      if (response.statusCode == 401) {
        await storage.delete(key: 'access_token');
      }

      return false;
    } catch (e) {
      log('Error uploading profile image: $e');
      return false;
    }
  }
}
