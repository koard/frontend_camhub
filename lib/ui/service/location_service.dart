import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../../models/location.dart';

class LocationService {
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

  /// Fetch all locations (public)
  static Future<List<Location>> fetchAll() async {
    final res = await http.get(_uri('/api/location/'));
    if (res.statusCode != 200) return [];
    final List<dynamic> jsonList = jsonDecode(res.body);
    return jsonList
        .whereType<Map>()
        .map((e) => Location.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// Fetch a single location by id (public)
  static Future<Location?> fetchById(int id) async {
    final res = await http.get(_uri('/api/location/$id'));
    if (res.statusCode != 200) return null;
    final Map<String, dynamic> map = Map<String, dynamic>.from(
      jsonDecode(res.body) as Map,
    );
    return Location.fromJson(map);
  }
}
