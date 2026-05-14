import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_tts/flutter_tts.dart';

import '../main.dart'; // فيه cameras

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController controller;
  late FlutterTts flutterTts;

  bool initialized = false;
  bool recording = false;
  String resultText = "—";

  @override
  void initState() {
    super.initState();

    // ===== TTS =====
    flutterTts = FlutterTts();
    flutterTts.setLanguage("ar-SA"); // عربي
    flutterTts.setSpeechRate(0.45);
    flutterTts.setPitch(1.0);

    final frontCam = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
    );

    controller = CameraController(
      frontCam,
      ResolutionPreset.high,
      enableAudio: false,
    );

    controller.initialize().then((_) {
      if (mounted) {
        setState(() => initialized = true);
      }
    });
  }

  Future<void> speak(String text) async {
    if (text.isNotEmpty) {
      await flutterTts.stop(); // يوقف أي صوت سابق
      await flutterTts.speak(text);
    }
  }

  Future<void> recordAndSend() async {
    if (recording) return;

    setState(() => recording = true);

    await controller.startVideoRecording();
    await Future.delayed(const Duration(seconds: 2));
    final file = await controller.stopVideoRecording();

    try {
      final request = http.MultipartRequest(
        "POST",
        Uri.parse("http://172.20.10.8:8000/upload_video"),
      );

      request.files.add(
        await http.MultipartFile.fromPath("file", file.path),
      );

      final response = await request.send();
      final resStr = await response.stream.bytesToString();
      final jsonRes = json.decode(resStr);

      final String text = jsonRes['text'] ?? "";

      double? confidence;
      if (jsonRes.containsKey('confidence') &&
          jsonRes['confidence'] != null) {
        confidence = (jsonRes['confidence'] as num).toDouble() * 100;
      }

      setState(() {
        resultText = confidence != null && confidence > 0
            ? "$text (${confidence.toStringAsFixed(1)}%)"
            : text;
      });

      // 🔊 قراءة النص بالصوت
      await speak(text);
    } catch (e) {
      setState(() {
        resultText = "خطأ في الاتصال بالسيرفر";
      });
    }

    setState(() => recording = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!initialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      children: [
        CameraPreview(controller),

        Positioned(
          bottom: 30,
          left: 0,
          right: 0,
          child: Column(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  resultText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontFamily: "PlaypenSansArabic",
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FloatingActionButton(
                onPressed: recordAndSend,
                backgroundColor: recording ? Colors.red : Colors.green,
                child: Icon(
                  recording ? Icons.stop : Icons.videocam,
                  size: 30,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    controller.dispose();
    flutterTts.stop();
    super.dispose();
  }
}
