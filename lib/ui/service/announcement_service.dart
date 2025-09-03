import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:campusapp/models/announcement.dart';

class AnnouncementService {
  static Future<List<Announcement>> fetchAll() async {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('announcements')
            .orderBy('date', descending: true)
            .get();

    return snapshot.docs
        .map((doc) => Announcement.fromJson(doc.data()))
        .toList();
  }

  static Future<List<Announcement>> fetchLatest({int limit = 3}) async {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('announcements')
            .orderBy('date', descending: true)
            .limit(limit)
            .get();

    return snapshot.docs
        .map((doc) => Announcement.fromJson(doc.data()))
        .toList();
  }
}
