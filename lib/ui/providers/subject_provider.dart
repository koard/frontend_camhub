import 'dart:convert';
import 'package:flutter/material.dart';
import '../../models/course.dart';
import '../../models/enrollment.dart';
import 'dart:developer';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SubjectProvider with ChangeNotifier {
  String get _baseUrl =>
      dotenv.env['API_BASE_URL']?.trim().replaceAll(RegExp(r"/+$"), '') ??
      'http://localhost:8000';

  List<Course> _courses = [];
  final List<Enrollment> _enrollments = [];
  final List<String> _registeredSubjectIds = [];
  final List<int> _registeredCourseIds = [];

  List<Course> get courses => _courses;
  List<Enrollment> get enrollments => _enrollments;
  List<String> get registeredSubjectIds => _registeredSubjectIds;
  List<int> get registeredCourseIds => _registeredCourseIds;

  Future<bool> checkCourseRegistration(int courseId) async {
    final storage = FlutterSecureStorage();
    final token = await storage.read(key: 'access_token');

    if (token == null) {
      return false;
    }

    try {
      final data = jsonDecode(token);
      final accessToken = data['access_token'];

      final uri = Uri.parse('$_baseUrl/api/enrollments/user');
      final res = await http.get(
        uri,
        headers: {
          'accept': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (res.statusCode == 200) {
        final List<dynamic> enrollments = jsonDecode(res.body);

        // ตรวจสอบว่า courseId นี้มีในรายการลงทะเบียนหรือไม่
        return enrollments.any(
          (enrollment) =>
              enrollment['course_id'] == courseId &&
              enrollment['status'] == 'enrolled',
        );
      }
    } catch (e) {
      log('Error checking course registration: $e');
    }

    return false;
  }

  Future<void> fetchCoursesFromApi() async {
    try {
      final uri = Uri.parse('$_baseUrl/api/courses');
      final res = await http.get(uri, headers: {'accept': 'application/json'});

      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        _courses =
            data.map((courseJson) => Course.fromJson(courseJson)).toList();

        // โหลดสถานะการลงทะเบียนสำหรับทุกคอร์ส
        await loadRegistrationStatus();

        notifyListeners();
      } else {
        throw Exception('Failed to load courses from API');
      }
    } catch (e) {
      throw Exception('Error fetching courses: $e');
    }
  }

  Future<void> loadRegistrationStatus() async {
    final storage = FlutterSecureStorage();
    final token = await storage.read(key: 'access_token');

    if (token == null) {
      return;
    }

    try {
      final data = jsonDecode(token);
      final accessToken = data['access_token'];

      final uri = Uri.parse('$_baseUrl/api/enrollments/user');
      final res = await http.get(
        uri,
        headers: {
          'accept': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (res.statusCode == 200) {
        final List<dynamic> enrollmentData = jsonDecode(res.body);

        // เคลียร์และอัพเดตรายการลงทะเบียน
        _registeredCourseIds.clear();
        _enrollments.clear();

        for (var enrollmentJson in enrollmentData) {
          final enrollment = Enrollment.fromJson(enrollmentJson);
          _enrollments.add(enrollment);

          if (enrollment.status == 'enrolled') {
            _registeredCourseIds.add(enrollment.courseId);
          }
        }
      }
    } catch (e) {
      log('Error loading registration status: $e');
    }
  }

  Future<void> fetchEnrollments() async {
    await loadRegistrationStatus();
    notifyListeners();
  }

  Future<void> _refreshCoursesData() async {
    try {
      final uri = Uri.parse('$_baseUrl/api/courses');
      final res = await http.get(uri, headers: {'accept': 'application/json'});

      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        _courses =
            data.map((courseJson) => Course.fromJson(courseJson)).toList();
      }
    } catch (e) {
      log('Error refreshing courses data: $e');
    }
  }

  bool isCourseRegistered(int courseId) {
    return _registeredCourseIds.contains(courseId);
  }

  Future<void> registerCourse(int courseId) async {
    final storage = FlutterSecureStorage();
    final token = await storage.read(key: 'access_token');

    if (token == null) {
      throw Exception('No authentication token found');
    }

    try {
      final data = jsonDecode(token);
      final accessToken = data['access_token'];

      final uri = Uri.parse('$_baseUrl/api/enrollments/enroll');
      final res = await http.post(
        uri,
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({'course_id': courseId}),
      );

      if (res.statusCode == 201 || res.statusCode == 200) {
        // อัพเดตสถานะท้องถิ่น
        if (!_registeredCourseIds.contains(courseId)) {
          _registeredCourseIds.add(courseId);
        }

        // รีเฟรชข้อมูลจาก API เพื่อให้แน่ใจว่าข้อมูลถูกต้อง
        await _refreshCoursesData();

        notifyListeners();
      } else {
        throw Exception('Failed to register course: ${res.body}');
      }
    } catch (e) {
      log('Error registering course: $e');
      throw Exception('Error registering course: $e');
    }
  }

  Future<void> unregisterCourse(int courseId) async {
    final storage = FlutterSecureStorage();
    final token = await storage.read(key: 'access_token');

    if (token == null) {
      throw Exception('No authentication token found');
    }

    try {
      final data = jsonDecode(token);
      final accessToken = data['access_token'];

      final uri = Uri.parse('$_baseUrl/api/enrollments/cancel/$courseId');
      final res = await http.delete(
        uri,
        headers: {
          'accept': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (res.statusCode == 200 || res.statusCode == 204) {
        // อัพเดตสถานะท้องถิ่น
        _registeredCourseIds.remove(courseId);
        notifyListeners();
      } else {
        throw Exception('Failed to unregister course: ${res.body}');
      }
    } catch (e) {
      log('Error unregistering course: $e');
      throw Exception('Error unregistering course: $e');
    }
  }
}
