import 'package:cloud_firestore/cloud_firestore.dart';

class AdminService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ================= LEVELS =================

  Future<void> addLevel(Map<String, dynamic> data) async {
    await _db.collection('levels').add(data);
  }

  Future<void> updateLevel(String id, Map<String, dynamic> data) async {
    await _db.collection('levels').doc(id).update(data);
  }

  Future<void> deleteLevel(String id) async {
    await _db.collection('levels').doc(id).delete();
  }

  // ================= STAGES =================

  Future<void> addStage(String levelId, Map<String, dynamic> data) async {
    await _db
        .collection('levels')
        .doc(levelId)
        .collection('stages')
        .add(data);
  }

  // ================= LESSONS =================

  Future<void> addLesson(
      String levelId, String stageId, Map<String, dynamic> data) async {
    await _db
        .collection('levels')
        .doc(levelId)
        .collection('stages')
        .doc(stageId)
        .collection('lessons')
        .add(data);
  }

  // ================= SIGN DICTIONARY =================

  Future<void> addSign(Map<String, dynamic> data) async {
    await _db.collection('sign_dictionary').add(data);
  }

  Future<void> updateSign(String id, Map<String, dynamic> data) async {
    await _db.collection('sign_dictionary').doc(id).update(data);
  }

  Future<void> deleteSign(String id) async {
    await _db.collection('sign_dictionary').doc(id).delete();
  }

  // ================= USERS =================

  Stream<QuerySnapshot> usersStream() {
    return _db.collection('users').snapshots();
  }

  // ================= ADMIN LOGS =================

  Future<void> logAction(String adminId, String action) async {
    await _db.collection('admin_logs').add({
      'adminId': adminId,
      'action': action,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
