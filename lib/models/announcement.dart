class Announcement {
  final int id;
  final String title;
  final String description;
  final String? imageUrl;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Announcement({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrl,
    this.startDate,
    this.endDate,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['image_url'],
      startDate:
          json['start_date'] != null
              ? DateTime.tryParse(json['start_date'].toString())
              : null,
      endDate:
          json['end_date'] != null
              ? DateTime.tryParse(json['end_date'].toString())
              : null,
      createdBy: json['created_by'],
      createdAt:
          json['created_at'] != null
              ? DateTime.tryParse(json['created_at'].toString())
              : null,
      updatedAt:
          json['updated_at'] != null
              ? DateTime.tryParse(json['updated_at'].toString())
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'image_url': imageUrl,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'created_by': createdBy,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // Helper getter for display date (use created_at as primary)
  DateTime? get displayDate => createdAt ?? updatedAt ?? startDate;
}
