import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _seqCtrl; // timeline controller
  late Timer _cursorTimer;
  bool _showCursor = true;

  // النصوص
  final String _tinyText = ""; // like "Let's go"
  final String _title = "!مرحباً بك في إشارة";
  final String _subtitle = "تعلّم، أشر، وتواصل بسهولة";

  @override
  void initState() {
    super.initState();

    // Timeline  : total duration ~4200ms (staggered phases)
    _seqCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    )..forward();

    // Blink cursor
    _cursorTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      setState(() => _showCursor = !_showCursor);
    });
  }

  @override
  void dispose() {
    _seqCtrl.dispose();
    _cursorTimer.cancel();
    super.dispose();
  }

  void _goNext() {
    Navigator.of(context).pushReplacementNamed('/onboarding1');
  }

  // يظهر جزء من النص حسب الفترة (start..end) داخل timeline
  String _typedText(String full, double start, double end) {
    final v = _seqCtrl.value;
    if (v <= start) return "";
    if (v >= end) return full;
    final local = ((v - start) / (end - start)).clamp(0.0, 1.0);
    final len = (full.length * local).floor();
    return full.substring(0, len);
  }

  // Animation interval helper for SlideTransition (from right -> left)
  Animation<Offset> _slideAnim(double start, double end) {
    return Tween<Offset>(begin: const Offset(0.5, 0), end: Offset.zero).animate(
      CurvedAnimation(parent: _seqCtrl, curve: Interval(start, end, curve: Curves.easeOut)),
    );
  }

  // Fade for Lottie and scale
  Animation<double> get _lottieFade => CurvedAnimation(parent: _seqCtrl, curve: const Interval(0.00, 0.25, curve: Curves.easeOut));
  Animation<double> get _lottieScale => Tween<double>(begin: 0.85, end: 1.00).animate(
      CurvedAnimation(parent: _seqCtrl, curve: const Interval(0.00, 0.25, curve: Curves.easeOutBack)));

  @override
  Widget build(BuildContext context) {
    const Color textDark = Color(0xFF0F172A);
    // sizes responsive
    final size = MediaQuery.of(context).size;
    final lottieSize = (size.width * 0.68).clamp(220.0, 360.0);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // الخلفية فقاعات (كما كانت)
          const Positioned.fill(child: _FadeBubblesBackground()),

          // المحتوى الرئيسي مع timeline AnimatedBuilder
          SafeArea(
            child: AnimatedBuilder(
              animation: _seqCtrl,
              builder: (context, child) {
                // intervals chosen (fractions of 0..1)
                // tinyText: 0.22 - 0.40
                // title:    0.35 - 0.70
                // subtitle: 0.65 - 0.90
                // skip btn: 0.90 - 1.00 (fade in)
                final tiny = _typedText(_tinyText, 0.22, 0.40);
                final titleTyped = _typedText(_title, 0.35, 0.70);
                final subTyped = _typedText(_subtitle, 0.65, 0.90);
                final showSkip = _seqCtrl.value >= 0.90;

                return Column(
                  children: [
                    const Spacer(),

                    // tiny text (like "Let's go!") — slide from right + type effect
                    SizedBox(
                      height: 28,
                      child: SlideTransition(
                        position: _slideAnim(0.22, 0.40),
                        child: Opacity(
                          opacity: (_seqCtrl.value >= 0.22) ? ((_seqCtrl.value - 0.22) / (0.40 - 0.22)).clamp(0.0, 1.0) : 0.0,
                          child: Text(
                            tiny + ((_showCursor && tiny.isNotEmpty) ? "|" : ""),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'PlaypenSansArabic',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF5BC0EB), // نفس السماوي
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Title (slide + typing)
                    SlideTransition(
                      position: _slideAnim(0.35, 0.70),
                      child: Opacity(
                        opacity: (_seqCtrl.value >= 0.35) ? ((_seqCtrl.value - 0.35) / (0.70 - 0.35)).clamp(0.0, 1.0) : 0.0,
                        child: Text(
                          // show typed + cursor while typing
                          titleTyped + ((_showCursor && titleTyped.isNotEmpty && _seqCtrl.value < 0.70) ? "|" : ""),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'PlaypenSansArabic',
                            fontSize: size.width > 420 ? 40 : 32,
                            fontWeight: FontWeight.w800,
                            color: textDark,
                            height: 1.20,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Subtitle (slide + typing)
                    SlideTransition(
                      position: _slideAnim(0.65, 0.90),
                      child: Opacity(
                        opacity: (_seqCtrl.value >= 0.65) ? ((_seqCtrl.value - 0.65) / (0.90 - 0.65)).clamp(0.0, 1.0) : 0.0,
                        child: Text(
                          subTyped + ((_showCursor && subTyped.isNotEmpty && _seqCtrl.value < 0.90) ? "|" : ""),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'PlaypenSansArabic',
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: textDark,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 22),

                    // اللوتي (يظهر أول، لكن نحتفظ بترتيب العرض لِما طلبت)
                    FadeTransition(
                      opacity: _lottieFade,
                      child: ScaleTransition(
                        scale: _lottieScale,
                        child: SizedBox(
                          width: lottieSize,
                          height: lottieSize,
                          child: Lottie.asset(
                            'assets/animations/wired-flat-2731-logo-circle-clubhouse-hover-pinch.json',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),

                    const Spacer(),

                    // زر التخطي في الأسفل-يمين كما قبل، يظهر بعد الـ 90%
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 20, bottom: 28),
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 300),
                          opacity: showSkip ? 1.0 : 0.0,
                          child: IgnorePointer(
                            ignoring: !showSkip,
                            child: _SkipTextButton(onTap: _goNext),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// زر "تخطي" نصّي (احتفظنا به كما في الكود القديم)
class _SkipTextButton extends StatefulWidget {
  final VoidCallback onTap;
  const _SkipTextButton({required this.onTap, super.key});

  @override
  State<_SkipTextButton> createState() => _SkipTextButtonState();
}

class _SkipTextButtonState extends State<_SkipTextButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    const Color yellow = Color(0xFFFACC15);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        splashColor: Colors.grey.withOpacity(0.25),
        onHighlightChanged: (v) => setState(() => _pressed = v),
        onTap: widget.onTap,
        child: AnimatedSlide(
          duration: const Duration(milliseconds: 150),
          offset: _pressed ? const Offset(-0.04, 0) : Offset.zero,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  "التالي",
                  style: TextStyle(
                    fontFamily: "PlaypenSansArabic",
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: yellow,
                  ),
                ),
                SizedBox(width: 4),
                Icon(Icons.arrow_forward_ios, size: 16, color: yellow),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/* ========== FadeBubblesBackground (نفسها كما كانت) ========== */
class _FadeBubblesBackground extends StatefulWidget {
  const _FadeBubblesBackground({super.key});

  @override
  State<_FadeBubblesBackground> createState() => _FadeBubblesBackgroundState();
}

class _FadeBubblesBackgroundState extends State<_FadeBubblesBackground>
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
    final size = MediaQuery.of(context).size;
    final List<_BubbleSpec> bubbles = [
      _BubbleSpec(Offset(size.width * .16, size.height * .18), 24, const Color(0xFFD0EFF7), 0.00),
      _BubbleSpec(Offset(size.width * .30, size.height * .28), 18, const Color(0xFFFACC15), 0.08),
      _BubbleSpec(Offset(size.width * .80, size.height * .22), 22, const Color(0xFFD0EFF7), 0.16),
      _BubbleSpec(Offset(size.width * .70, size.height * .36), 26, const Color(0xFFFACC15), 0.24),
      _BubbleSpec(Offset(size.width * .22, size.height * .55), 20, const Color(0xFFD0EFF7), 0.32),
      _BubbleSpec(Offset(size.width * .88, size.height * .58), 16, const Color(0xFFFACC15), 0.40),
      _BubbleSpec(Offset(size.width * .12, size.height * .74), 22, const Color(0xFFD0EFF7), 0.48),
      _BubbleSpec(Offset(size.width * .44, size.height * .82), 18, const Color(0xFFFACC15), 0.56),
      _BubbleSpec(Offset(size.width * .68, size.height * .76), 24, const Color(0xFFD0EFF7), 0.64),
      _BubbleSpec(Offset(size.width * .86, size.height * .84), 20, const Color(0xFFFACC15), 0.72),
      _BubbleSpec(Offset(size.width * .50, size.height * .14), 18, const Color(0xFFD0EFF7), 0.80),
      _BubbleSpec(Offset(size.width * .56, size.height * .60), 26, const Color(0xFFFACC15), 0.88),
    ];

    return AnimatedBuilder(
      animation: _t,
      builder: (_, __) {
        return CustomPaint(
          painter: _FadeBubblesPainter(progress: _t.value, bubbles: bubbles),
        );
      },
    );
  }
}

class _BubbleSpec {
  final Offset origin;
  final double radius;
  final Color color;
  final double phase;
  const _BubbleSpec(this.origin, this.radius, this.color, this.phase);
}

class _FadeBubblesPainter extends CustomPainter {
  final double progress; // 0..1
  final List<_BubbleSpec> bubbles;

  _FadeBubblesPainter({required this.progress, required this.bubbles});

  @override
  void paint(Canvas canvas, Size size) {
    for (final b in bubbles) {
      final t = (progress + b.phase) % 1.0;
      final signal = (sin(2 * pi * t) + 1) / 2; // 0..1
      final baseOpacity =
      (b.color.value == const Color(0xFFD0EFF7).value) ? 0.50 : 0.40;
      final opacity = (0.15 + signal * baseOpacity).clamp(0.0, 1.0);
      final scale = 0.9 + signal * 0.15;
      final radius = b.radius * scale;

      final paint = Paint()..color = b.color.withOpacity(opacity);
      canvas.drawCircle(b.origin, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _FadeBubblesPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.bubbles != bubbles;
}
