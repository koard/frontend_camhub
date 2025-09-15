class FacultyModel {
  final int id;
  final String name;

  FacultyModel({required this.id, required this.name});

  factory FacultyModel.fromJson(Map<String, dynamic> json) {
    return FacultyModel(id: json['id'], name: json['name']);
  }
}
