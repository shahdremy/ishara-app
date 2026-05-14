import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ishara/auth/auth_wrapper.dart';
import 'package:ishara/screens/camera_screen.dart';
import 'package:ishara/services/dictionary_sync_service.dart';
import 'package:ishara/services/notification_service.dart';
import 'package:ishara/services/offline_dictionary.dart';

import 'firebase_options.dart';
// الشاشات
import 'screens/splash_screen.dart';
import 'screens/register_screen.dart';
import 'screens/main_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/translate_screen.dart';
import 'screens/learning_screen.dart';
import 'screens/onboarding1_screen.dart';
import 'screens/onboarding2_screen.dart';
import 'package:camera/camera.dart';

late List<CameraDescription> cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🟢 الكاميرا (آمنة)
  try {
    cameras = await availableCameras();
  } catch (e) {
    debugPrint('⚠️ Camera init failed: $e');
  }

  // 🟢 Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 🟢 الإشعارات (لازم تكون هنا)
  try {
    await NotificationService.init();
  } catch (e) {
    debugPrint('⚠️ Notification init failed: $e');
  }

  // 🟢 مزامنة القاموس (آمنة)
  try {
    await DictionarySyncService.syncIfNeeded();
  } catch (e) {
    debugPrint('⚠️ Dictionary sync skipped: $e');
  }

  // 🟢 تحميل القاموس الأوفلاين
  try {
    await OfflineDictionary.load();
  } catch (e) {
    debugPrint('⚠️ Offline dictionary load failed: $e');
  }

  // ✅ مهم جدًا: runApp لازم يوصلها
  runApp(const MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'إشارة',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
      ),
      home:const AuthWrapper(),

    routes: {
        '/onboarding1': (_) => const Onboarding1Screen(),
        '/onboarding2': (_) => const Onboarding2Screen(),
        '/register': (_) => const RegisterScreen(),
        '/main': (_) => const MainScreen(),
        '/translate': (_) => const TranslateScreen(),
        '/learning': (_) => LearningScreen(),
        '/camera': (_) => const CameraScreen(),
        '/settings': (_) => const SettingsScreen(),
      },
    );
  }
}