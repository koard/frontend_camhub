import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class EventsProvider {
  // Set API_BASE_URL in assets/.env and ensure dotenv is loaded in main.dart
  final String _baseUrl;

  EventsProvider({String? baseUrl})
      : _baseUrl = baseUrl ?? (dotenv.env['API_BASE_URL'] ?? 'http://127.0.0.1:8000');

  String get _normalizedBaseUrl =>
      _baseUrl.endsWith('/') ? _baseUrl.substring(0, _baseUrl.length - 1) : _baseUrl;

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final uri = Uri.parse('$_normalizedBaseUrl$path');
    if (query == null || query.isEmpty) return uri;
    return uri.replace(
      queryParameters: query.map((k, v) => MapEntry(k, v?.toString())),
    );
  }

  Future<List<Map<String, dynamic>>> fetchEvents() async {
    final resp = await http.get(
      _uri('/api/events', {
        'include_enrolled_count': 'true',
      }),
    );

    if (resp.statusCode != 200) {
      throw Exception('Failed to fetch events (${resp.statusCode}): ${resp.body}');
    }

    final List<dynamic> jsonList = json.decode(resp.body) as List<dynamic>;
    // Normalize fields to match current UI usage (expects `name`, not `title`)
    return jsonList.map<Map<String, dynamic>>((e) {
      final map = Map<String, dynamic>.from(e as Map);
      map['name'] = map['title'];
      // Dates are already ISO strings from the API; keep as-is for UI parsing
      return map;
    }).toList();
  }

  Future<Map<String, dynamic>> fetchEventById(int id, {bool publicView = true}) async {
    final path = publicView ? '/api/events/public/$id' : '/api/events/$id';
    final resp = await http.get(_uri(path));
    if (resp.statusCode != 200) {
      throw Exception('Failed to fetch event $id (${resp.statusCode}): ${resp.body}');
    }
    final Map<String, dynamic> map = json.decode(resp.body) as Map<String, dynamic>;
    map['name'] = map['title'];
    return map;
  }

  // The following write operations require backend authentication (Bearer token)
  // and specific payload formats. Provide implementations when auth is wired.
  Future<void> addEvent(Map<String, dynamic> eventData) async {
    throw UnimplementedError('addEvent requires FastAPI auth; not implemented in frontend yet.');
  }

  Future<void> updateEvent(
    String eventId,
    Map<String, dynamic> eventData,
  ) async {
    throw UnimplementedError('updateEvent requires FastAPI auth; not implemented in frontend yet.');
  }

  Future<void> deleteEvent(String eventId) async {
    throw UnimplementedError('deleteEvent requires FastAPI auth; not implemented in frontend yet.');
  }
}
