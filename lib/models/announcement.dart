import 'package:cloud_firestore/cloud_firestore.dart';

class Announcement {
  final String title;
  final String description;
  final String? author;
  final DateTime? date;

  Announcement({
    required this.title,
    required this.description,
    this.author,
    this.date,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      author: json['author'],
      date:
          (json['date'] is Timestamp)
              ? (json['date'] as Timestamp).toDate()
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'author': author,
      'date': date != null ? Timestamp.fromDate(date!) : null,
    };
  }
}
