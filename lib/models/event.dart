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
        ? (json['start_date'] is String
          ? DateTime.tryParse(json['start_date'] as String)
          : null)
        : null,
    endDate:
      json['end_date'] != null
        ? (json['end_date'] is String
          ? DateTime.tryParse(json['end_date'] as String)
          : null)
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
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'image_url': imageUrl,
      'participants': participants,
    };
  }
}
