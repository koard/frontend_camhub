class Course {
  final int id;
  final String courseCode;
  final String courseName;
  final int credits;
  final int availableSeats;
  final String description;
  final String createdAt;
  final int enrolledCount;

  Course({
    required this.id,
    required this.courseCode,
    required this.courseName,
    required this.credits,
    required this.availableSeats,
    required this.description,
    required this.createdAt,
    required this.enrolledCount,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'] ?? 0,
      courseCode: json['course_code'] ?? '',
      courseName: json['course_name'] ?? '',
      credits: json['credits'] ?? 0,
      availableSeats: json['available_seats'] ?? 0,
      description: json['description'] ?? '',
      createdAt: json['created_at'] ?? '',
      enrolledCount: json['enrolled_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'course_code': courseCode,
      'course_name': courseName,
      'credits': credits,
      'available_seats': availableSeats,
      'description': description,
      'created_at': createdAt,
      'enrolled_count': enrolledCount,
    };
  }

  // Helper getter for display purposes
  String get availabilityText {
    final remaining = availableSeats - enrolledCount;
    return 'ที่นั่งคงเหลือ: $remaining/$availableSeats';
  }

  bool get isAvailable {
    return (availableSeats - enrolledCount) > 0;
  }
}
