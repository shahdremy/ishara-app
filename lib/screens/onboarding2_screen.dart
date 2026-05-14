import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:ishara/screens/register_screen.dart';
import '../widgets/shared_dots.dart'; // ✅ النقاط الموحدة
import 'package:shared_preferences/shared_preferences.dart';

class Onboarding2Screen extends StatefulWidget {
  const Onboarding2Screen({super.key});

  @override
  State<Onboarding2Screen> createState() => _Onboarding2ScreenState();
}

class _Onboarding2ScreenState extends State<Onboarding2Screen>
    with SingleTickerProviderStateMixin {

  Future<void> _goRegister(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seen_onboarding', true);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
  }


  @override
  Widget build(BuildContext context) {
    const textDark = Color(0xFF0F172A);
    const yellow = Color(0xFFFACC15);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          const Positioned.fill(child: _BubblesBackground()),

          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 56),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 25),
                  child: Text(
                    "وصّل القفاز بالبلوتوث أو وجّه الكاميرا، وشاهد كلامك يتحوّل نصًا وصوتًا فورًا🤩!\u200F",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'PlaypenSansArabic',
                      fontSize: 26,
                      fontWeight: FontWeight.w500,
                      color: textDark,
                      height: 1.45,
                    ),
                  ),
                ),

                const SizedBox(height: 22),

                Expanded(
                  child: Center(
                    child: Image.asset(
                      'assets/images/ChatGPT Image Oct 6, 2025, 12_47_39 PM.png',
                      width: MediaQuery.of(context).size.width * 0.84,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // زر "ابدأ" محدث
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GestureDetector(
                    onTap: () => _goRegister(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 64,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFCE96A), yellow],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: yellow.withOpacity(0.32),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Text(
                        "ابدأ",
                        style: TextStyle(
                          fontFamily: 'PlaypenSansArabic',
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // ✅ نقاط التنقل الموحّدة
                const SharedDotsIndicator(currentIndex: 1),

                const SizedBox(height: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/* ===== خلفية الفقاعات ===== */
class _BubblesBackground extends StatefulWidget {
  const _BubblesBackground({super.key});
  @override
  State<_BubblesBackground> createState() => _BubblesBackgroundState();
}

class _BubblesBackgroundState extends State<_BubblesBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _t;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
    _t = CurvedAnimation(parent: _ctrl, curve: Curves.linear);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = MediaQuery.of(context).size;
    final bubbles = <_Bubble>[
      _Bubble(Offset(s.width * .15, s.height * .22), 24, const Color(0xFFD0EFF7), 0.00),
      _Bubble(Offset(s.width * .80, s.height * .20), 22, const Color(0xFFFACC15), 0.10),
      _Bubble(Offset(s.width * .70, s.height * .35), 26, const Color(0xFFD0EFF7), 0.20),
      _Bubble(Offset(s.width * .22, s.height * .55), 20, const Color(0xFFFACC15), 0.30),
      _Bubble(Offset(s.width * .12, s.height * .78), 22, const Color(0xFFD0EFF7), 0.40),
      _Bubble(Offset(s.width * .44, s.height * .82), 18, const Color(0xFFFACC15), 0.50),
      _Bubble(Offset(s.width * .12, s.height * .71), 25, const Color(0xFFD0EFF7), 0.40),
      _Bubble(Offset(s.width * .44, s.height * .82), 18, const Color(0xFFFACC15), 0.50),
    ];

    return AnimatedBuilder(
      animation: _t,
      builder: (_, __) => CustomPaint(
        painter: _BubblesPainter(progress: _t.value, bubbles: bubbles),
      ),
    );
  }
}

class _Bubble {
  final Offset origin;
  final double radius;
  final Color color;
  final double phase;
  const _Bubble(this.origin, this.radius, this.color, this.phase);
}

class _BubblesPainter extends CustomPainter {
  final double progress;
  final List<_Bubble> bubbles;
  const _BubblesPainter({required this.progress, required this.bubbles});

  @override
  void paint(Canvas canvas, Size size) {
    for (final b in bubbles) {
      final t = (progress + b.phase) % 1.0;
      final signal = (math.sin(2 * math.pi * t) + 1) / 2;

      final baseOpacity =
      (b.color.value == const Color(0xFFD0EFF7).value) ? 0.45 : 0.35;
      final opacity = (0.15 + signal * baseOpacity).clamp(0.0, 1.0);
      final scale = 0.92 + signal * 0.14;
      final r = b.radius * scale;

      final paint = Paint()..color = b.color.withOpacity(opacity);
      canvas.drawCircle(b.origin, r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BubblesPainter old) =>
      old.progress != progress || old.bubbles != bubbles;
}
