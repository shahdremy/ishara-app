import 'dart:math';
import 'package:flutter/material.dart';
import '../widgets/shared_dots.dart'; // ✅ جديد

class Onboarding1Screen extends StatefulWidget {
  const Onboarding1Screen({super.key});

  @override
  State<Onboarding1Screen> createState() => _Onboarding1ScreenState();
}

class _Onboarding1ScreenState extends State<Onboarding1Screen>
    with TickerProviderStateMixin {
  late final AnimationController _moveCtrl;
  late final Animation<double> _moveAnim;

  @override
  void initState() {
    super.initState();
    // حركة أوضح وأبطأ
    _moveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )..repeat(reverse: true);

    _moveAnim = Tween<double>(begin: -16, end: 16)
        .chain(CurveTween(curve: Curves.easeInOut))
        .animate(_moveCtrl);
  }

  @override
  void dispose() {
    _moveCtrl.dispose();
    super.dispose();
  }

  void _goNext(BuildContext context) {
    Navigator.pushReplacementNamed(context, '/onboarding2');
  }


  @override
  Widget build(BuildContext context) {
    const textDark = Color(0xFF0F172A);
    const yellow = Color(0xFFFACC15);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            const Positioned.fill(child: _BubblesBackground()),

            Directionality(
              textDirection: TextDirection.rtl,
              child: Column(
                children: [
                  const SizedBox(height: 24),

                  // العنوان + الوصف
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    child: Column(
                      children: const [
                        Text(
                          "افتح باب تواصل جديد\u200F!",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'PlaypenSansArabic',
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                            color: textDark,
                            height: 1.25,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          "تعلّم الحروف والكلمات والإشارات اليومية بخطوات قصيرة وممتعة.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'PlaypenSansArabic',
                            fontSize: 18,
                            color: textDark,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // الهاتف + الصور المتحركة
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, c) {
                        final phoneW = min(c.maxWidth * 0.60, 340.0);
                        final phoneH = phoneW * 2.1;
                        final bezelR = phoneW * 0.15;
                        final notchW = phoneW * 0.34;
                        final notchH = max(12.0, phoneW * 0.045);
                        final cardW = phoneW * 0.78;
                        final cardH = cardW * 0.62;
                        const cardRadius = 18.0;
                        final overhang = phoneW * 0.10;

                        return Center(
                          child: SizedBox(
                            width: phoneW,
                            height: phoneH,
                            child: AnimatedBuilder(
                              animation: _moveAnim,
                              builder: (context, _) {
                                // قيم إزاحة مختلفة قليلاً لكل صورة عشان الإحساس الطبيعي
                                final dx1 = _moveAnim.value;           // يمين/يسار
                                final dx2 = -_moveAnim.value * 0.9;     // عكس مع تخفيض بسيط
                                final dx3 = _moveAnim.value * 0.75;     // أهدى شوية

                                return Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    // إطار الهاتف الأسود
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black,
                                        borderRadius:
                                        BorderRadius.circular(bezelR),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                            Colors.black.withOpacity(.18),
                                            blurRadius: 28,
                                            offset: const Offset(0, 16),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // الشاشة الداخلية
                                    Positioned.fill(
                                      left: 4,
                                      right: 4,
                                      top: 4,
                                      bottom: 4,
                                      child: ClipRRect(
                                        borderRadius:
                                        BorderRadius.circular(bezelR - 6),
                                        child: Container(
                                            color: const Color(0xFFF8FAFC)),
                                      ),
                                    ),

                                    // النوتش
                                    Positioned(
                                      top: phoneH * 0.035,
                                      left: (phoneW - notchW) / 2,
                                      child: Container(
                                        width: notchW,
                                        height: notchH,
                                        decoration: BoxDecoration(
                                          color: Colors.black,
                                          borderRadius:
                                          BorderRadius.circular(48),
                                        ),
                                      ),
                                    ),

                                    // الصور (مع ظل 3D خفيف) + حركة يمين/يسار
                                    _CardImage(
                                      path:
                                      "assets/images/asl-writing-a-visual-language-2.jpg",
                                      width: cardW,
                                      height: cardH,
                                      radius: 18,
                                      left: (phoneW - cardW) / 2 + overhang + dx1,
                                      top: phoneH * 0.16,
                                    ),
                                    _CardImage(
                                      path:
                                      "assets/images/istockphoto-1498825958-640x640.jpg",
                                      width: cardW,
                                      height: cardH,
                                      radius: 18,
                                      left: (phoneW - cardW) / 2 - overhang + dx2,
                                      top: phoneH * 0.42,
                                    ),
                                    _CardImage(
                                      path:
                                      "assets/images/How-Many-Sign-Languages-Are-There.jpg",
                                      width: cardW,
                                      height: cardH,
                                      radius: 18,
                                      left: (phoneW - cardW) / 2 + overhang + dx3,
                                      top: phoneH * 0.68,
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // نقاط + "التالي"
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    child: Stack(
                      children: [
                        // ✅ نقاط موحّدة في المنتصف
                        const Align(
                          alignment: Alignment.center,
                          child: SharedDotsIndicator(currentIndex: 0),
                        ),

                        // زر "التالي" على اليمين
                        Align(
                          alignment: Alignment.centerRight,
                          child: GestureDetector(
                            onTap: () => _goNext(context),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Text(
                                  "التالي",
                                  style: TextStyle(
                                    fontFamily: 'PlaypenSansArabic',
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: yellow,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Icon(Icons.arrow_forward_ios,
                                    size: 16, color: yellow),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dot(bool active) => Container(
    width: active ? 22 : 8,
    height: 8,
    decoration: BoxDecoration(
      color:
      active ? const Color(0xFFFACC15) : const Color(0xFFE5E7EB),
      borderRadius: BorderRadius.circular(20),
    ),
  );
}

/* ===== Card Image ===== */
class _CardImage extends StatelessWidget {
  final String path;
  final double width, height, radius, left, top;

  const _CardImage({
    required this.path,
    required this.width,
    required this.height,
    required this.radius,
    required this.left,
    required this.top,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: top,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.12),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.asset(path, fit: BoxFit.cover),
      ),
    );
  }
}

/* ===== خلفية فقاعات ===== */
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
    _ctrl =
    AnimationController(vsync: this, duration: const Duration(seconds: 6))
      ..repeat();
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
      _Bubble(Offset(s.width * .15, s.height * .22), 24,
          const Color(0xFFD0EFF7), 0.00),
      _Bubble(Offset(s.width * .80, s.height * .20), 22,
          const Color(0xFFFACC15), 0.10),
      _Bubble(Offset(s.width * .70, s.height * .35), 26,
          const Color(0xFFD0EFF7), 0.20),
      _Bubble(Offset(s.width * .22, s.height * .55), 20,
          const Color(0xFFFACC15), 0.30),
      _Bubble(Offset(s.width * .12, s.height * .78), 22,
          const Color(0xFFD0EFF7), 0.40),
      _Bubble(Offset(s.width * .44, s.height * .82), 18,
          const Color(0xFFFACC15), 0.50),
      _Bubble(Offset(s.width * .68, s.height * .76), 24,
          const Color(0xFFD0EFF7), 0.60),
      _Bubble(Offset(s.width * .86, s.height * .84), 20,
          const Color(0xFFFACC15), 0.70),
      _Bubble(Offset(s.width * .50, s.height * .14), 18,
          const Color(0xFFD0EFF7), 0.80),
    ];

    return AnimatedBuilder(
      animation: _t,
      builder: (_, __) =>
          CustomPaint(painter: _BubblesPainter(progress: _t.value, bubbles: bubbles)),
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
      final signal = (sin(2 * pi * t) + 1) / 2;
      final baseOpacity =
      (b.color.value == const Color(0xFFD0EFF7).value) ? 0.45 : 0.35;
      final opacity = (0.12 + signal * baseOpacity).clamp(0.0, 1.0);
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
