import 'course_schedule.dart';

class Enrollment {
  final int id;
  final int courseId;
  final int userId;
  final String? courseCode;
  final String status;
  final String enrollmentAt;
  final String fullname;
  final String courseName;
  // Optional schedules returned by enrollment API (nested list)
  final List<CourseSchedule> schedules;

  Enrollment({
    required this.id,
    required this.courseId,
    required this.courseCode,
    required this.userId,
    required this.status,
    required this.enrollmentAt,
    required this.fullname,
    required this.courseName,
    this.schedules = const [],
  });

  factory Enrollment.fromJson(Map<String, dynamic> json) {
    // Parse nested schedules if present
    List<CourseSchedule> parsedSchedules = [];
    final dynamic schedulesJson = json['schedules'];
    if (schedulesJson is List) {
      parsedSchedules =
          schedulesJson
              .whereType<Map<String, dynamic>>()
              .map((e) => CourseSchedule.fromJson(e))
              .toList();
    }

    return Enrollment(
      id: json['id'] ?? 0,
      courseId: json['course_id'] ?? 0,
      courseCode: json['course_code'] ?? '',
      userId: json['user_id'] ?? 0,
      status: json['status'] ?? '',
      enrollmentAt: json['enrollment_at'] ?? '',
      fullname: json['fullname'] ?? '',
      courseName: json['course_name'] ?? '',
      schedules: parsedSchedules,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'course_id': courseId,
      'user_id': userId,
      'status': status,
      'enrollment_at': enrollmentAt,
      'fullname': fullname,
      'course_name': courseName,
      'schedules': schedules.map((e) => e.toJson()).toList(),
    };
  }

  // Helper getter for display date
  DateTime? get enrollmentDate {
    try {
      return DateTime.parse(enrollmentAt);
    } catch (e) {
      return null;
    }
  }

  // Helper getter for formatted date
  String get formattedEnrollmentDate {
    final date = enrollmentDate;
    if (date != null) {
      return '${date.day}/${date.month}/${date.year}';
    }
    return '';
  }

  bool get hasSchedules => schedules.isNotEmpty;
}
