class Location {
  final int id;
  final String name;
  final String code;
  final double? latitude;
  final double? longitude;
  final String? description;

  const Location({
    required this.id,
    required this.name,
    required this.code,
    this.latitude,
    this.longitude,
    this.description,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    double? asDouble(dynamic v) {
      if (v == null) return null;
      if (v is double) return v;
      if (v is int) return v.toDouble();
      return double.tryParse(v.toString());
    }

    return Location(
      id: (json['id'] as num).toInt(),
      name: (json['name'] ?? '').toString(),
      code: (json['code'] ?? '').toString(),
      latitude: asDouble(json['latitude']),
      longitude: asDouble(json['longitude']),
      description: json['description']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'code': code,
        'latitude': latitude,
        'longitude': longitude,
        'description': description,
      };
}
