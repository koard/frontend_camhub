class CourseSchedule {
  final int id;
  final int courseId;
  final String courseCode;
  final int roomId;
  final String dayOfWeek;
  final String startTime;
  final String endTime;
  // Optional human-friendly room name when provided by API (e.g., from nested objects)
  final String? roomName;

  CourseSchedule({
    required this.id,
    required this.courseId,
    required this.courseCode,
    required this.roomId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.roomName,
  });

  factory CourseSchedule.fromJson(Map<String, dynamic> json) {
    // Handle both flat shapes and nested room objects
    String? resolvedRoomName;
    if (json.containsKey('room_name')) {
      resolvedRoomName = json['room_name']?.toString();
    } else if (json['room'] is Map<String, dynamic>) {
      final room = json['room'] as Map<String, dynamic>;
      resolvedRoomName =
          (room['name'] ?? room['room_name'] ?? room['code'])?.toString();
    }

    return CourseSchedule(
      id: json['id'] ?? 0,
      courseId: json['course_id'] ?? 0,
      courseCode: json['course_code']?.toString() ?? '',
      roomId:
          json['room_id'] is int
              ? (json['room_id'] as int)
              : int.tryParse(json['room_id']?.toString() ?? '') ?? 0,
      dayOfWeek: json['day_of_week']?.toString() ?? '',
      startTime: json['start_time']?.toString() ?? '',
      endTime: json['end_time']?.toString() ?? '',
      roomName: resolvedRoomName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'course_id': courseId,
      'course_code': courseCode,
      'room_id': roomId,
      'day_of_week': dayOfWeek,
      'start_time': startTime,
      'end_time': endTime,
      if (roomName != null) 'room_name': roomName,
    };
  }

  String get formattedTimeRange {
    final start = _formatTime(startTime);
    final end = _formatTime(endTime);
    return '$start - $end';
  }

  String _formatTime(String value) {
    if (value.isEmpty) return '';
    if (value.contains(':')) {
      final parts = value.split(':');
      if (parts.length >= 2) {
        return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
      }
    }
    return value;
  }
}
