import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial_plus/flutter_bluetooth_serial_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import 'select_device_page.dart';
import '../services/bluetooth_service.dart';
import '../services/offline_dictionary.dart';
import '../services/tts_service.dart';

class GloveScreen extends StatefulWidget {
  const GloveScreen({super.key});

  @override
  State<GloveScreen> createState() => _GloveScreenState();
}

class _GloveScreenState extends State<GloveScreen> {
  BluetoothConnection? _connection;
  StreamSubscription<Uint8List>? _dataSubscription;

  bool isConnected = false;
  String connectionStatus = "لم يتم الاتصال بالقفاز";
  String translatedText = "الترجمة ستظهر هنا";

  final BluetoothService _bluetoothService = BluetoothService();

  @override
  void initState() {
    super.initState();
    TtsService.init();

    _bluetoothService.codeStream.listen(_handleGloveCode);
  }

  Future<bool> _requestBluetoothPermissions() async {
    await Permission.bluetoothConnect.request();
    await Permission.bluetoothScan.request();
    await Permission.location.request();
    return true;
  }

  void _handleGloveCode(String code) {
    final item = OfflineDictionary.findByGloveCode(code);
    if (item != null) {
      setState(() => translatedText = item['text']);
      TtsService.speak(item['text']); // ✅ لن ينطق إذا الصوت مطفأ
    } else {
      setState(() => translatedText = "غير معروف");
    }
  }


  Future<void> connectManually() async {
    await _requestBluetoothPermissions();

    final BluetoothDevice? device = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SelectDevicePage()),
    );

    if (device == null) return;

    setState(() => connectionStatus = "🔄 جاري الاتصال بالقفاز...");

    try {
      _connection?.finish();
      _connection = await BluetoothConnection.toAddress(device.address);

      setState(() {
        isConnected = true;
        connectionStatus = "✅ تم الاتصال بالقفاز";
      });

      _dataSubscription = _connection!.input!.listen(
            (Uint8List data) {
          final raw = String.fromCharCodes(data);
          _bluetoothService.onDataReceived(raw);
        },
        onDone: _handleDisconnect,
        onError: (_) => _handleDisconnect(),
        cancelOnError: false,
      );
    } catch (e) {
      setState(() => connectionStatus = "❌ فشل الاتصال");
    }
  }

  void _handleDisconnect() {
    if (!mounted) return;
    setState(() {
      isConnected = false;
      connectionStatus = "❌ تم فصل الاتصال";
    });
    _connection?.finish();
    _connection = null;
  }

  Future<void> disconnectDevice() async {
    await _dataSubscription?.cancel();
    await _connection?.finish();
    _connection = null;

    setState(() {
      isConnected = false;
      connectionStatus = "❌ تم فصل الاتصال";
    });
  }

  // ================= UI (كما كان بالزبط) =================

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context).size;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _statusBox(mq),
              const SizedBox(width: 10),
              _mainButton(
                icon: isConnected
                    ? Icons.bluetooth_disabled
                    : Icons.bluetooth_searching,
                text: isConnected ? "قطع الاتصال" : "ربط بالقفاز",
                color1: Colors.amber,
                color2: Colors.orangeAccent,
                width: mq.width * 0.35,
                height: mq.height * 0.06,
                onTap: isConnected ? disconnectDevice : connectManually,
              ),
            ],
          ),
          SizedBox(height: mq.height * 0.06),
          _translationBox(mq),
          SizedBox(height: mq.height * 0.03),
          _mainButton(
            icon: Icons.volume_up,
            text: "تشغيل الصوت",
            color1: Colors.lightBlueAccent,
            color2: Colors.blueAccent,
            width: mq.width * 0.6,
            height: mq.height * 0.07,
            onTap: () => TtsService.speak(translatedText), // ✅ يعتمد على الصوت المفعّل
          ),

        ],
      ),
    );
  }

  Widget _statusBox(Size mq) {
    return Container(
      width: mq.width * 0.45,
      height: mq.height * 0.06,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: isConnected
            ? Colors.blueAccent.withOpacity(0.1)
            : Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: isConnected ? Colors.blueAccent : Colors.amber,
          width: 2,
        ),
      ),
      child: Text(
        connectionStatus,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontFamily: "PlaypenSansArabic",
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _translationBox(Size mq) {
    return Container(
      width: mq.width * 0.7,
      height: mq.height * 0.15,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Text(
        translatedText,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontFamily: "PlaypenSansArabic",
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _mainButton({
    required IconData icon,
    required String text,
    required Color color1,
    required Color color2,
    required VoidCallback onTap,
    required double width,
    required double height,
    bool isBlackText = false, // ✅ لتغيير لون النص حسب الحاجة
  }) {
    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton.icon(
        icon: Icon(
          icon,
          color: Colors.white,
          size: height * 0.5, // 🔹 حجم الايقونة نصف ارتفاع الزر
        ),
        label: Text(
          text,
          style: TextStyle(
            fontFamily: "PlaypenSansArabic",
            fontSize: height * 0.35, // 🔹 حجم الخط حسب ارتفاع الزر
            fontWeight: FontWeight.w600,
            color: isBlackText ? Colors.black : Colors.white,
          ),
        ),
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(height * 0.5), // 🔹 دائري متناسب مع ارتفاع
          ),
          padding: EdgeInsets.symmetric(horizontal: height * 0.3), // 🔹 Padding داخلي نسبي
        ),
      ),
    );
  }

}
