import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  static final FlutterTts _tts = FlutterTts();

  // 🔹 حالة الصوت (مفعّل/مطفي)
  static bool _enabled = true;

  // ===== تهيئة الخدمة =====
  static Future<void> init() async {
    await _tts.setLanguage("ar");
    await _tts.setSpeechRate(0.45);
  }

  // ===== تفعيل/تعطيل الصوت =====
  static void setEnabled(bool enabled) {
    _enabled = enabled;
  }

  // ===== التحدث =====
  static Future<void> speak(String text) async {
    if (!_enabled) return; // ❌ لا ينطق إذا الصوت مطفأ
    if (text.isEmpty) return;
    await _tts.speak(text);
  }
}
