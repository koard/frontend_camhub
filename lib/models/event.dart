import 'package:cloud_firestore/cloud_firestore.dart';

class Event {
  final String name;
  final String description;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? imageUrl;
  final List<String>? participants;

  Event({
    required this.name,
    required this.description,
    this.startDate,
    this.endDate,
    this.imageUrl,
    this.participants,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      startDate:
          json['start_date'] != null
              ? (json['start_date'] is Timestamp
                  ? (json['start_date'] as Timestamp).toDate()
                  : DateTime.tryParse(json['start_date']))
              : null,
      endDate:
          json['end_date'] != null
              ? (json['end_date'] is Timestamp
                  ? (json['end_date'] as Timestamp).toDate()
                  : DateTime.tryParse(json['end_date']))
              : null,
      imageUrl: json['image_url'],
      participants:
          json['participants'] != null
              ? List<String>.from(json['participants'])
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'start_date': startDate != null ? Timestamp.fromDate(startDate!) : null,
      'end_date': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'image_url': imageUrl,
      'participants': participants,
    };
  }
}
