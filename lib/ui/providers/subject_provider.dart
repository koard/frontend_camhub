import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/subject.dart';

class SubjectProvider with ChangeNotifier {
  List<Subject> _subjects = [];
  final List<String> _registeredSubjectIds = [];

  List<Subject> get subjects => _subjects;
  List<String> get registeredSubjectIds => _registeredSubjectIds;

  Future<void> loadSubjects() async {
    final String jsonString = await rootBundle.loadString(
      'assets/mock_subjects/mock_subjects.json',
    );
    final List<dynamic> jsonData = json.decode(jsonString);
    _subjects = jsonData.map((e) => Subject.fromJson(e)).toList();
    notifyListeners();
  }

  void registerSubject(String subjectId) {
    if (!_registeredSubjectIds.contains(subjectId)) {
      _registeredSubjectIds.add(subjectId);
      notifyListeners();
    }
  }

  void unregisteredSubject(String subjectId) {
    if (_registeredSubjectIds.contains(subjectId)) {
      _registeredSubjectIds.remove(subjectId);
      notifyListeners();
    }
  }

  bool isRegistered(String subjectId) {
    return _registeredSubjectIds.contains(subjectId);
  }
}
