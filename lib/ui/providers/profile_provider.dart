import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  final CollectionReference users = FirebaseFirestore.instance.collection(
    'users',
  );

  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    final docSnapshot = await users.doc(uid).get();
    if (!docSnapshot.exists) return null;
    return docSnapshot.data() as Map<String, dynamic>;
  }
}
