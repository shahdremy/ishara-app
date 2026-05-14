import 'dart:math';
import 'package:flutter/material.dart';
import 'package:ishara/screens/camera_screen.dart';
import 'package:ishara/services/notification_service.dart';
import '../widgets/bubble_background.dart';
import 'glove_screen.dart';

class TranslateScreen extends StatefulWidget {
  const TranslateScreen({super.key});

  @override
  State<TranslateScreen> createState() => _TranslateScreenState();
}

class _TranslateScreenState extends State<TranslateScreen>
    with SingleTickerProviderStateMixin {
  bool showChoice = true;
  bool isGloveMode = false;

  late AnimationController _t;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      NotificationService.show(
        id: 11,
        title: '✋ جرّب الترجمة',
        body: 'حوّل الكلمات لإشارات بسهولة في تطبيق إشارة',
      );
    });
    _t = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _t.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    final List<BubbleSpec> bubbles = [
      BubbleSpec(Offset(size.width * .16, size.height * .18), 24,
          const Color(0xFFD0EFF7), 0.00),
      BubbleSpec(Offset(size.width * .30, size.height * .28), 18,
          const Color(0xFFFACC15), 0.08),
      BubbleSpec(Offset(size.width * .80, size.height * .22), 22,
          const Color(0xFFD0EFF7), 0.16),
      BubbleSpec(Offset(size.width * .70, size.height * .36), 26,
          const Color(0xFFFACC15), 0.24),
      BubbleSpec(Offset(size.width * .22, size.height * .55), 20,
          const Color(0xFFD0EFF7), 0.32),
      BubbleSpec(Offset(size.width * .88, size.height * .58), 16,
          const Color(0xFFFACC15), 0.40),
      BubbleSpec(Offset(size.width * .12, size.height * .74), 22,
          const Color(0xFFD0EFF7), 0.48),
      BubbleSpec(Offset(size.width * .44, size.height * .82), 18,
          const Color(0xFFFACC15), 0.56),
      BubbleSpec(Offset(size.width * .68, size.height * .76), 24,
          const Color(0xFFD0EFF7), 0.64),
      BubbleSpec(Offset(size.width * .86, size.height * .84), 20,
          const Color(0xFFFACC15), 0.72),
      BubbleSpec(Offset(size.width * .50, size.height * .14), 18,
          const Color(0xFFD0EFF7), 0.80),
      BubbleSpec(Offset(size.width * .56, size.height * .60), 26,
          const Color(0xFFFACC15), 0.88),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _t,
            builder: (_, __) {
              return CustomPaint(
                painter:
                FadeBubblesPainter(progress: _t.value, bubbles: bubbles),
                size: size,
              );
            },
          ),
          SafeArea(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: showChoice
                  ? _buildChoiceView()
                  : isGloveMode
                  ? _buildGloveWrapper()
                  : _buildCameraWrapper(),
            ),
          ),
        ],
      ),
    );
  }

  // =================== اختيار نوع الترجمة ===================
  Widget _buildChoiceView() {
    final mq = MediaQuery.of(context).size;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "اختر نوع الترجمة",
            style: TextStyle(
              fontFamily: "PlaypenSansArabic",
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0D1B2A),
            ),
          ),
          SizedBox(height: mq.height * 0.05),
          _buildMainButton(
            icon: Icons.front_hand_rounded,
            text: "ترجمة القفاز",
            color1: Colors.amber,
            color2: Colors.yellowAccent,
            onTap: () {
              setState(() {
                showChoice = false;
                isGloveMode = true;
              });
            },
          ),
          SizedBox(height: mq.height * 0.03),
          _buildMainButton(
            icon: Icons.camera_alt_rounded,
            text: "ترجمة بالكاميرا",
            color1: Colors.lightBlueAccent,
            color2: Colors.blueAccent,
            onTap: () {
              setState(() {
                showChoice = false;
                isGloveMode = false;
              });
            },
          ),
          SizedBox(height: mq.height * 0.03),
          _buildMainButton(
            icon: Icons.text_snippet_rounded,
            text: "ترجمة نص الى إشارة",
            color1: const Color(0xFF9AD0EC),
            color2: const Color(0xFF7BBDEB),
            onTap: () {
              // واجهة فقط حالياً
            },
          ),

        ],
      ),
    );
  }

  // =================== Wrapper القفاز ===================
  Widget _buildGloveWrapper() {
    return Column(
      children: [
        _buildBackButton(),
        const Expanded(child: GloveScreen()),
      ],
    );
  }

  // =================== Wrapper الكاميرا ===================
  Widget _buildCameraWrapper() {
    return Column(
      children: [
        _buildBackButton(),
        const Expanded(child: CameraScreen()),
      ],
    );
  }

  Widget _buildBackButton() {
    return Align(
      alignment: Alignment.topLeft,
      child: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            color: Colors.blue),
        onPressed: () {
          setState(() {
            showChoice = true;
          });
        },
      ),
    );
  }

  // =================== زر موحد ===================
  Widget _buildMainButton({
    required IconData icon,
    required String text,
    required Color color1,
    required Color color2,
    required VoidCallback onTap,
  }) {
    final mq = MediaQuery.of(context).size;

    return Container(
      width: mq.width * 0.6,
      height: mq.height * 0.07,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color1, color2]),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: color2.withOpacity(0.4),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: Colors.white),
        label: Text(
          text,
          style: const TextStyle(
            fontFamily: "PlaypenSansArabic",
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        ),
      ),
    );
  }
}
