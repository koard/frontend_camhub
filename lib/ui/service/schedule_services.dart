import 'dart:convert';
import 'dart:developer';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:io';

/// ScheduleCourseService
/// โครงสร้างการเขียนให้มีรูปแบบเดียวกับ UserService (profile_service.dart)
/// - ดึง token จาก secure storage (คาดหวังรูปแบบ JSON {"access_token": "..."})
/// - แนบ Authorization header
/// - log สถานะ response
/// - ล้าง token เมื่อโดน 401
class ScheduleCourseService {
  String get _baseUrl =>
      dotenv.env['API_BASE_URL']?.trim().replaceAll(RegExp(r'/+$'), '') ??
      'http://localhost:8000';

  /// ดึงตารางเรียนทั้งหมดของผู้ใช้
  /// Endpoint: GET /api/course_schedules/schedules/user
  Future<List<Map<String, dynamic>>> getScheduleCourses() async {
    final storage = FlutterSecureStorage();
    final token = await storage.read(key: 'access_token');
    log('[Schedule] Raw stored token: $token');

    if (token == null || token.isEmpty) {
      log('[Schedule] No token found');
      return <Map<String, dynamic>>[];
    }
    // ดึง access token (รองรับทั้งรูปแบบ JSON และสตริงดิบ) → ให้ได้ non-null เสมอ
    late final String accessToken;
    try {
      final decoded = jsonDecode(token);
      if (decoded is Map &&
          decoded['access_token'] is String &&
          (decoded['access_token'] as String).isNotEmpty) {
        accessToken = decoded['access_token'] as String;
      } else {
        accessToken = token; // fallback ไปใช้สตริงที่อ่านมาโดยตรง
      }
    } catch (_) {
      accessToken = token; // ไม่ใช่ JSON
    }

    if (accessToken.isEmpty) {
      return <Map<String, dynamic>>[];
    }

    final uri = Uri.parse('$_baseUrl/api/course_schedules/schedules/user');

    try {
      final res = await http.get(
        uri,
        headers: {
          'accept': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );
      log('[Schedule] Status: ${res.statusCode}');

      if (res.statusCode >= 200 && res.statusCode < 300) {
        if (res.body.isEmpty) {
          return <Map<String, dynamic>>[];
        }
        final decoded = jsonDecode(res.body);
        if (decoded is List) {
          final list = decoded.whereType<Map<String, dynamic>>().toList(
            growable: false,
          );
          // Save raw list to file for offline fallback
          _persistLatestScheduleFile(list);
          return list;
        } else {
          log('[Schedule] Unexpected body shape (not List)');
          return <Map<String, dynamic>>[];
        }
      }

      if (res.statusCode == 401) {
        await storage.delete(key: 'access_token');
      }
      return <Map<String, dynamic>>[];
    } catch (e, st) {
      log('[Schedule] Exception: $e\n$st');
      return <Map<String, dynamic>>[];
    }
  }

  // ------------- File based offline backup (raw JSON) -------------
  static const String _fileName = 'latest_schedule.json';

  Future<File?> _getScheduleFile() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      return File('${dir.path}/$_fileName');
    } catch (e) {
      log('[Schedule][File] Get file error: $e');
      return null;
    }
  }

  Future<void> _persistLatestScheduleFile(
    List<Map<String, dynamic>> data,
  ) async {
    try {
      final f = await _getScheduleFile();
      if (f == null) return;
      await f.writeAsString(jsonEncode(data), flush: true);
      log('[Schedule][File] Saved schedule file (${data.length} items)');
    } catch (e) {
      log('[Schedule][File] Save error: $e');
    }
  }

  Future<List<Map<String, dynamic>>> loadLatestScheduleFromFile() async {
    try {
      final f = await _getScheduleFile();
      if (f == null) return <Map<String, dynamic>>[];
      if (!await f.exists()) return <Map<String, dynamic>>[];
      final content = await f.readAsString();
      if (content.isEmpty) return <Map<String, dynamic>>[];
      final decoded = jsonDecode(content);
      if (decoded is List) {
        return decoded
            .whereType<Map>()
            .map((e) => e.map((k, v) => MapEntry(k.toString(), v)))
            .cast<Map<String, dynamic>>()
            .toList(growable: false);
      }
    } catch (e) {
      log('[Schedule][File] Load error: $e');
    }
    return <Map<String, dynamic>>[];
  }

  /// Fetch with file fallback (priority: network -> file -> empty)
  Future<List<Map<String, dynamic>>> getScheduleWithFileFallback() async {
    final remote = await getScheduleCourses();
    if (remote.isNotEmpty) return remote;
    final fileData = await loadLatestScheduleFromFile();
    if (fileData.isNotEmpty) {
      log('[Schedule][File] Using file cached schedule (${fileData.length})');
      return fileData;
    }
    return <Map<String, dynamic>>[];
  }

  /// บันทึกตาราง (ที่มีอยู่ในหน่วยความจำปัจจุบัน) ลงไฟล์แบบ manual
  /// ใช้ตอนต้องการ ensure ว่า state ล่าสุดถูก persist ก่อนผู้ใช้ปิดแอป
  Future<void> persistScheduleToFile(List<Map<String, dynamic>> data) async {
    await _persistLatestScheduleFile(data);
  }

  /// ลบไฟล์ cache (เรียกตอน logout)
  Future<void> clearScheduleFileCache() async {
    try {
      final f = await _getScheduleFile();
      if (f != null && await f.exists()) {
        await f.delete();
        log('[Schedule][File] Deleted schedule cache file');
      }
    } catch (e) {
      log('[Schedule][File] Delete error: $e');
    }
  }
}
