import 'package:campusapp/models/announcement.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:developer';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AnnouncementService {
  String get _baseUrl =>
      dotenv.env['API_BASE_URL']?.trim().replaceAll(RegExp(r"/+$"), '') ??
      'http://localhost:8000';

  Future<List<Announcement>> getAnnouncements() async {
    final uri = Uri.parse('$_baseUrl/api/annc');
    final res = await http.get(uri, headers: {'accept': 'application/json'});
    if (res.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(res.body);
      return jsonList.map((json) => Announcement.fromJson(json)).toList();
    } else {
      log('Failed to fetch announcements: ${res.statusCode}');
      return [];
    }
  }
}
