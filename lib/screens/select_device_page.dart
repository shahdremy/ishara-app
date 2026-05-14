import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial_plus/flutter_bluetooth_serial_plus.dart';

class SelectDevicePage extends StatelessWidget {
  const SelectDevicePage({super.key});

  final Color primaryYellow = const Color(0xFFFACC15);
  final Color primarySkyBlue = const Color(0xFF5BC0EB);
  final String mainFont = 'PlaypenSansArabic';

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: primaryYellow,
        title: const Text(
          "اختيار القفاز",
          style: TextStyle(fontFamily: 'PlaypenSansArabic'),
        ),
        centerTitle: true,
        elevation: 4,
      ),
      body: FutureBuilder<List<BluetoothDevice>>(
        future: FlutterBluetoothSerial.instance.getBondedDevices(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFFACC15),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: mq.width * 0.1),
                child: Text(
                  "لا توجد أجهزة مقترنة\n\nاعمل Pair للـ ESP32 من إعدادات البلوتوث",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: mainFont,
                    fontSize: mq.width * 0.045,
                    color: Colors.black87,
                  ),
                ),
              ),
            );
          }

          final devices = snapshot.data!;
          return ListView.builder(
            padding: EdgeInsets.symmetric(vertical: mq.height * 0.02),
            itemCount: devices.length,
            itemBuilder: (_, i) {
              final d = devices[i];
              return Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: mq.width * 0.05, vertical: mq.height * 0.01),
                child: Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                  child: ListTile(
                    leading: Container(
                      width: mq.width * 0.12,
                      height: mq.width * 0.12,
                      decoration: BoxDecoration(
                        color: primarySkyBlue.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.bluetooth,
                        color: primarySkyBlue,
                        size: mq.width * 0.07,
                      ),
                    ),
                    title: Text(
                      d.name ?? "جهاز مجهول",
                      style: TextStyle(
                        fontFamily: mainFont,
                        fontSize: mq.width * 0.045,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      d.address,
                      style: TextStyle(
                        fontFamily: mainFont,
                        fontSize: mq.width * 0.035,
                        color: Colors.black54,
                      ),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                    onTap: () => Navigator.pop(context, d),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
