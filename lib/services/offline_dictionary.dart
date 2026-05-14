import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class OfflineDictionary {
  static List<Map<String, dynamic>> _items = [];

  static Future<void> load() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/sign_dictionary.json');

      if (!await file.exists()) {
        _items = [];
        print('❌ Offline dictionary file does not exist yet.');
        return;
      }

      final jsonString = await file.readAsString();
      _items = List<Map<String, dynamic>>.from(json.decode(jsonString));

      // ✅ تأكيد تحميل القاموس بنجاح
      print('✅ Offline dictionary loaded with ${_items.length} entries.');
    } catch (e) {
      print('❌ Error loading offline dictionary: $e');
      _items = [];
    }
  }

  static Map<String, dynamic>? findByGloveCode(String code) {
    try {
      return _items.firstWhere(
            (e) => e['glove']?['exists'] == true && e['glove']?['code'] == code,
      );
    } catch (_) {
      return null;
    }
  }
}
