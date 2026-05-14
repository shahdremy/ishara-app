import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';

class DictionarySyncService {
  static const fileName = 'sign_dictionary.json';

  static Future<void> syncIfNeeded() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$fileName');

      await _downloadFromFirebase(file);

      // ✅ تأكيد نجاح التحميل
      print('⬇️ Dictionary downloaded successfully at ${file.path}');
    } catch (e) {
      print('❌ Failed to download dictionary: $e');
    }
  }

  static Future<void> _downloadFromFirebase(File file) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('sign_dictionary')
        .where('enabled', isEqualTo: true)
        .get();

    final List<Map<String, dynamic>> cleanData = [];

    for (var doc in snapshot.docs) {
      final raw = doc.data();

      // 🔧 تنظيف Timestamp
      raw.forEach((key, value) {
        if (value is Timestamp) {
          raw[key] = value.toDate().toIso8601String();
        }
      });

      cleanData.add(raw);
    }

    await file.writeAsString(jsonEncode(cleanData));

    // ✅ هنا نطبع رسالة نجاح إضافية
    print('✅ Dictionary file written with ${cleanData.length} entries.');
  }
}
