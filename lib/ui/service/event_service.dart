import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:campusapp/models/event.dart';

class EventService {
  static Future<List<Event>> fetchAll() async {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('events')
            .orderBy('start_date', descending: true)
            .get();

    return snapshot.docs.map((doc) => Event.fromJson(doc.data())).toList();
  }

  static Future<List<Event>> fetchLatest({int limit = 3}) async {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('events')
            .orderBy('start_date', descending: true)
            .limit(limit)
            .get();

    return snapshot.docs.map((doc) => Event.fromJson(doc.data())).toList();
  }
}
