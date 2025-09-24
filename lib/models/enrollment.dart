class Enrollment {
  final int id;
  final int courseId;
  final int userId;
  final String status;
  final String enrollmentAt;
  final String fullname;
  final String courseName;

  Enrollment({
    required this.id,
    required this.courseId,
    required this.userId,
    required this.status,
    required this.enrollmentAt,
    required this.fullname,
    required this.courseName,
  });

  factory Enrollment.fromJson(Map<String, dynamic> json) {
    return Enrollment(
      id: json['id'] ?? 0,
      courseId: json['course_id'] ?? 0,
      userId: json['user_id'] ?? 0,
      status: json['status'] ?? '',
      enrollmentAt: json['enrollment_at'] ?? '',
      fullname: json['fullname'] ?? '',
      courseName: json['course_name'] ?? '',
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
}
