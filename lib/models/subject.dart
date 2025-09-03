class Subject {
  final String subjectId;
  final String subject;
  final String teacher;
  final String day;
  final String startTime;
  final String endTime;
  final String room;
  final int credit;

  Subject({
    required this.subjectId,
    required this.subject,
    required this.teacher,
    required this.day,
    required this.startTime,
    required this.endTime,
    required this.room,
    required this.credit,
  });

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      subjectId: json['subject_id'],
      subject: json['subject'],
      teacher: json['teacher'],
      day: json['day'],
      startTime: json['start_time'],
      endTime: json['end_time'],
      room: json['room'],
      credit: json['credit'],
    );
  }
}
