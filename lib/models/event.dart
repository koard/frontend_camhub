class Event {
  final int? id;
  final String name;
  final String description;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? imageUrl;
  final List<String>? participants;
  final String? location;

  Event({
    this.id,
    required this.name,
    required this.description,
    this.startDate,
    this.endDate,
    this.imageUrl,
    this.participants,
    this.location,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: _asInt(json['id']),
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
      location: json['location'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'image_url': imageUrl,
      'participants': participants,
      'location': location,
    };
  }
}

int? _asInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is double) return v.toInt();
  return int.tryParse(v.toString());
}

// (No lat/lng here; event keeps only location name)
