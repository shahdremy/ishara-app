import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ishara/services/app_state_service.dart';
import 'main_screen.dart'; // تأكد من المسار الصحيح لشاشتك الرئيسية

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passCtrl = TextEditingController();

  bool isLogin = true;

  late final AnimationController _bubblesCtrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _bubblesCtrl =
    AnimationController(vsync: this, duration: const Duration(seconds: 7))
      ..repeat();
    _anim = CurvedAnimation(parent: _bubblesCtrl, curve: Curves.linear);
  }

  @override
  void dispose() {
    _bubblesCtrl.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    return email.contains('@') && email.contains('.');
  }

  bool _isValidName(String name) {
    final regex = RegExp(r'^[a-zA-Z\u0600-\u06FF\s]+$');
    return regex.hasMatch(name);
  }

  //  إنشاء الحساب
  Future<void> _register() async {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text.trim();

    if (name.isEmpty || email.isEmpty || pass.isEmpty) {
      return _showMessageDialog(
        title: "خطأ",
        message: "يرجى تعبئة جميع الحقول.",
        success: false,
      );
    }

    if (!_isValidName(name)) {
      return _showMessageDialog(
        title: "الاسم غير صالح",
        message: "يرجى إدخال حروف فقط (عربي أو إنجليزي).",
        success: false,
      );
    }

    if (!_isValidEmail(email)) {
      return _showMessageDialog(
        title: "البريد الإلكتروني غير صالح",
        message: "يرجى إدخال بريد صحيح.",
        success: false,
      );
    }

    if (pass.length < 5) {
      return _showMessageDialog(
        title: "كلمة السر قصيرة",
        message: "يجب ألا تقل عن 5 أحرف.",
        success: false,
      );
    }

    try {
      final cred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: email,
        password: pass,
      );

      await cred.user!.updateDisplayName(name);
      await cred.user!.reload(); 

      //  هنا لا حاجة لـ Navigator
      _showMessageDialog(
        title: "تم التسجيل",
        message: "تم إنشاء الحساب بنجاح.",
        success: true,
      );
    } on FirebaseAuthException catch (e) {
      String msg = "حدث خطأ أثناء إنشاء الحساب.";
      if (e.code == 'email-already-in-use') {
        msg = "هذا البريد مستخدم مسبقًا.";
      } else if (e.code == 'invalid-email') {
        msg = "البريد الإلكتروني غير صالح.";
      } else if (e.code == 'weak-password') {
        msg = "كلمة المرور ضعيفة.";
      }

      return _showMessageDialog(title: "خطأ", message: msg, success: false);
    }
  }

  Future<void> _login() async {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text.trim();

    if (email.isEmpty || pass.isEmpty) {
      return _showMessageDialog(
        title: "خطأ",
        message: "يرجى تعبئة جميع الحقول.",
        success: false,
      );
    }

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: pass,
      );

      // ⭐⭐⭐ هذا السطر هو الحل
      await AppStateService.clearManualLogout();

      // ✅ لا Navigator
      _showMessageDialog(
        title: "تم الدخول",
        message: "تم تسجيل الدخول بنجاح.",
        success: true,
      );
    } on FirebaseAuthException catch (e) {
      String msg = "البريد أو كلمة المرور غير صحيحة.";
      if (e.code == 'invalid-email') {
        msg = "البريد الإلكتروني غير صالح.";
      } else if (e.code == 'user-not-found') {
        msg = "لا يوجد حساب بهذا البريد.";
      } else if (e.code == 'wrong-password') {
        msg = "كلمة المرور غير صحيحة.";
      }

      return _showMessageDialog(
        title: "خطأ",
        message: msg,
        success: false,
      );
    }
  }

  void _showMessageDialog({
    required String title,
    required String message,
    required bool success,
    VoidCallback? onClose,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.white.withOpacity(0.95),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                success ? Icons.check_circle : Icons.error_outline,
                size: 56,
                color: success ? Colors.green : Colors.red,
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: const TextStyle(
                    fontFamily: 'PlaypenSansArabic',
                    fontSize: 18,
                    fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: const TextStyle(
                    fontFamily: 'PlaypenSansArabic', fontSize: 15),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onClose ?? () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                  success ? const Color(0xFFFACC15) : Colors.blueAccent,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  "حسنًا",
                  style: TextStyle(
                      fontFamily: 'PlaypenSansArabic', fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final width = mq.size.width;
    final height = mq.size.height;
    final double buttonWidth = width > 600 ? 360 : width * 0.62;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          const Positioned.fill(child: _BubblesBackground()),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                    horizontal: width * 0.06, vertical: height * 0.04),
                child: Column(
                  children: [
                    Text(
                      isLogin ? "تسجيل الدخول" : "إنشاء حساب جديد",
                      style: const TextStyle(
                        fontFamily: 'PlaypenSansArabic',
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          if (!isLogin)
                            _modernField(
                              controller: _nameCtrl,
                              label: "الاسم الكامل",
                              icon: Icons.person,
                              width: width,
                            ),
                          if (!isLogin) const SizedBox(height: 12),
                          _modernField(
                            controller: _emailCtrl,
                            label: "الإيميل",
                            icon: Icons.email,
                            width: width,
                          ),
                          const SizedBox(height: 12),
                          _modernField(
                            controller: _passCtrl,
                            label: "كلمة السر",
                            icon: Icons.lock,
                            obscure: true,
                            width: width,
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: buttonWidth,
                            child: ElevatedButton(
                              onPressed: isLogin ? _login : _register,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFACC15),
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(28),
                                ),
                              ),
                              child: Text(
                                isLogin ? "تسجيل الدخول" : "تسجيل",
                                style: const TextStyle(
                                  fontFamily: 'PlaypenSansArabic',
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                isLogin = !isLogin;
                                _nameCtrl.clear();
                                _emailCtrl.clear();
                                _passCtrl.clear();
                              });
                            },
                            child: Text(
                              isLogin
                                  ? "إنشاء حساب جديد"
                                  : "العودة لتسجيل الدخول",
                              style: const TextStyle(
                                fontFamily: 'PlaypenSansArabic',
                                fontSize: 15,
                                decoration: TextDecoration.underline,
                                color: Color(0xFF2196F3),
                              ),
                            ),
                          )
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _modernField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
    required double width,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        cursorColor: const Color(0xFF2196F3),
        style: const TextStyle(
          fontFamily: 'PlaypenSansArabic',
          color: Color(0xFF0F172A),
        ),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: const Color(0xFF2196F3)),
          labelText: label,
          labelStyle: const TextStyle(
            fontFamily: 'PlaypenSansArabic',
            color: Color(0xFF6B7280),
          ),
          filled: true,
          fillColor: Colors.white.withOpacity(0.4),
          contentPadding:
          const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

// فقاعات الخلفية
class _BubblesBackground extends StatefulWidget {
  const _BubblesBackground({super.key});

  @override
  State<_BubblesBackground> createState() => _BubblesBackgroundState();
}

class _BubblesBackgroundState extends State<_BubblesBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _t;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 6))
      ..repeat();
    _t = CurvedAnimation(parent: _c, curve: Curves.linear);
  }

  @override
  void dispose() {
    _c.dispose();
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
          const Color(0xFFD0EFF7), 0.25),
    ];

    return AnimatedBuilder(
      animation: _t,
      builder: (_, __) => CustomPaint(
        painter: _BubblesPainter(bubbles, _t.value),
      ),
    );
  }
}

class _Bubble {
  final Offset position;
  final double size;
  final Color color;
  final double phase;

  _Bubble(this.position, this.size, this.color, this.phase);
}

class _BubblesPainter extends CustomPainter {
  final List<_Bubble> bubbles;
  final double value;

  _BubblesPainter(this.bubbles, this.value);

  @override
  void paint(Canvas canvas, Size size) {
    for (final b in bubbles) {
      final dy = math.sin((value + b.phase) * 2 * math.pi) * 10;
      final offset = Offset(b.position.dx, b.position.dy + dy);
      final paint = Paint()..color = b.color.withOpacity(0.8);
      canvas.drawCircle(offset, b.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
