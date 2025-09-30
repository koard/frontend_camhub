import 'dart:convert';
import 'package:campusapp/models/event.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class EventService {
  static String get _baseUrl =>
      dotenv.env['API_BASE_URL']?.trim().replaceAll(RegExp(r"/+$$"), '') ??
      'http://127.0.0.1:8000';

  static Uri _uri(String path, [Map<String, dynamic>? query]) {
    final uri = Uri.parse('$_baseUrl$path');
    if (query == null || query.isEmpty) return uri;
    return uri.replace(
      queryParameters: query.map((k, v) => MapEntry(k, v?.toString())),
    );
  }

  static Future<List<Event>> fetchAll() async {
    final res = await http.get(_uri('/api/events', {'include_enrolled_count': 'true'}));
    if (res.statusCode != 200) return [];
    final List<dynamic> jsonList = jsonDecode(res.body);
    return jsonList.map((e) {
      final map = Map<String, dynamic>.from(e as Map);
      map['name'] = map['title'];
      return Event.fromJson(map);
    }).toList();
  }

  static Future<List<Event>> fetchLatest({int limit = 3}) async {
    final res = await http.get(_uri('/api/events', {
      'include_enrolled_count': 'true',
    }));
    if (res.statusCode != 200) return [];
    final List<dynamic> jsonList = jsonDecode(res.body);
    final events = jsonList.map((e) {
      final map = Map<String, dynamic>.from(e as Map);
      map['name'] = map['title'];
      return Event.fromJson(map);
    }).toList();
    events.sort((a, b) {
      final ad = a.startDate ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bd = b.startDate ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bd.compareTo(ad);
    });
    return events.take(limit).toList();
  }

  // Fetch normal event details by id
  static Future<Map<String, dynamic>?> fetchById(int eventId) async {
    final res = await http.get(_uri('/api/events/$eventId'));
    if (res.statusCode != 200) return null;
    final map = Map<String, dynamic>.from(jsonDecode(res.body) as Map);
    map['name'] = map['title'] ?? map['name'];
    return map;
  }

  // Fetch public event details by id for deep link navigation
  static Future<Map<String, dynamic>?> fetchPublicById(int eventId) async {
    final res = await http.get(_uri('/api/events/public/$eventId'));
    if (res.statusCode != 200) return null;
    final map = Map<String, dynamic>.from(jsonDecode(res.body) as Map);
    // Align field naming expected by UI (some parts read 'name')
    map['name'] = map['title'] ?? map['name'];
    return map;
  }
}
