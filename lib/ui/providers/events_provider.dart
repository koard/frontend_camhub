import 'package:cloud_firestore/cloud_firestore.dart';

class EventsProvider {
  final CollectionReference eventsCollection = FirebaseFirestore.instance
      .collection('events');

  Future<List<Map<String, dynamic>>> fetchEvents() async {
    final querySnapshot = await eventsCollection.get();
    return querySnapshot.docs
        .map((doc) => doc.data() as Map<String, dynamic>)
        .toList();
  }

  Future<void> addEvent(Map<String, dynamic> eventData) async {
    await eventsCollection.add(eventData);
  }

  Future<void> updateEvent(
    String eventId,
    Map<String, dynamic> eventData,
  ) async {
    await eventsCollection.doc(eventId).update(eventData);
  }

  Future<void> deleteEvent(String eventId) async {
    await eventsCollection.doc(eventId).delete();
  }
}
