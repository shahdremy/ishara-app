import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ishara/services/app_state_service.dart';
import 'package:ishara/services/tts_service.dart';
import 'package:shared_preferences/shared_preferences.dart';



class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  String name = 'مستخدم';
  String email = '';
  bool darkMode = false;
  bool notifications = true;
  bool sounds = true;
  String language = 'العربية';

  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
    AnimationController(vsync: this, duration: const Duration(seconds: 10))
      ..repeat(reverse: true);

    _loadUserData();
    _loadSoundsSetting();



  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _loadUserData() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      name = user.displayName ?? 'مستخدم';
      email = user.email ?? '';
    });
  }
  void _editProfileDialog(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    TextEditingController nameController = TextEditingController(text: name);
    TextEditingController emailController = TextEditingController(text: email);
    TextEditingController passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(
          'تعديل الحساب',
          style: TextStyle(fontFamily: 'PlaypenSansArabic'),
        ),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'الاسم'),
              ),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'البريد الإلكتروني'),
              ),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'كلمة المرور (للتأكيد)',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'إلغاء',
              style: TextStyle(fontFamily: 'PlaypenSansArabic'),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = nameController.text.trim();
              final newEmail = emailController.text.trim();
              final password = passwordController.text.trim();

              try {
                if (user == null) return;

                if (newName.isNotEmpty && newName != user.displayName) {
                  await user.updateDisplayName(newName);
                  await user.reload();

                  final refreshedUser = FirebaseAuth.instance.currentUser;

                  setState(() {
                    name = refreshedUser?.displayName ?? name;
                    email = refreshedUser?.email ?? email;
                  });
              }

                // تحديث الإيميل مع إعادة المصادقة
                if (newEmail.isNotEmpty && newEmail != user.email) {
                  if (password.isEmpty) {
                    _showError(context, 'يرجى إدخال كلمة المرور لتحديث الإيميل');
                    return;
                  }
                  final cred = EmailAuthProvider.credential(
                    email: user.email!,
                    password: password,
                  );
                  await user.updateEmail(newEmail);
                  await user.reload(); // ✅
                  final refreshedUser = FirebaseAuth.instance.currentUser;
                  setState(() => email = refreshedUser?.email ?? newEmail);
                }

                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'تم تحديث البيانات بنجاح',
                      style: TextStyle(fontFamily: 'PlaypenSansArabic'),
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              } on FirebaseAuthException catch (e) {
                _showError(context, e.code == 'wrong-password'
                    ? 'كلمة المرور غير صحيحة'
                    : 'فشل تحديث البيانات');
              }
            },
            child: const Text('حفظ', style: TextStyle(fontFamily: 'PlaypenSansArabic')),
          ),
        ],
      ),
    );
  }




  Future<void> _logout() async {
    await AppStateService.setManualLogout(true); // ⭐ مهم
    await FirebaseAuth.instance.signOut();
    // ❗ لا Navigator
    // authStateChanges في main.dart يتكفل بالباقي
  }

  Future<void> _deleteAccount(
      BuildContext context,
      String password,
      ) async {
    final auth = FirebaseAuth.instance;
    final user = auth.currentUser;

    if (user == null || user.email == null) {
      _showError(context, 'لا يوجد مستخدم مسجل');
      return;
    }

    try {
      _showLoading(context, text: 'جاري حذف الحساب...');

      // 🔐 إعادة المصادقة
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(cred);

      final uid = user.uid;

      // 🧹 حذف بيانات المستخدم من Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .delete();

      // 🗑️ حذف حساب Firebase Auth
      await user.delete();
      await AppStateService.setManualLogout(true);

      _hideLoading(context);

      // ❗️ لا Navigator هنا
      // authStateChanges في main.dart يتكفل بالخروج

    } on FirebaseAuthException catch (e) {
      _hideLoading(context);

      String msg;
      switch (e.code) {
        case 'wrong-password':
          msg = 'كلمة المرور غير صحيحة';
          break;
        case 'requires-recent-login':
          msg = 'يرجى تسجيل الدخول من جديد';
          break;
        default:
          msg = 'فشل حذف الحساب';
      }

      _showError(context, msg);
    } catch (e) {
      _hideLoading(context);
      _showError(context, 'حدث خطأ غير متوقع');
    }
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontFamily: 'PlaypenSansArabic'),
        ),
        backgroundColor: Colors.red,
      ),
    );
  }
  void _hideLoading(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }
  void _showLoading(BuildContext context, {String text = 'جاري التنفيذ...'}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(fontFamily: 'PlaypenSansArabic'),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Future<void> _loadSoundsSetting() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      sounds = prefs.getBool('sounds') ?? true; // الافتراضي true
    });
    TtsService.setEnabled(sounds); // مزامنة مع TTS
  }

  void _showReAuthMessage(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(
          'إعادة تسجيل الدخول',
          style: TextStyle(fontFamily: 'PlaypenSansArabic'),
        ),
        content: const Text(
          'لأسباب أمنية، الرجاء تسجيل الدخول من جديد ثم محاولة حذف الحساب.',
          style: TextStyle(fontFamily: 'PlaypenSansArabic'),
        ),
        actions: [
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseAuth.instance.signOut();
            },
            child: const Text(
              'حسناً',
              style: TextStyle(fontFamily: 'PlaypenSansArabic'),
            ),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('الإعدادات',
            style: TextStyle(
              fontFamily: 'PlaypenSansArabic',
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            )),
        centerTitle: true,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Stack(
          children: [
            // فقاعات متحركة
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Stack(
                  children: [
                    _animatedBubble(-30, -20, 70,
                        Colors.yellow.withOpacity(0.25), 0),
                    _animatedBubble(
                        100, -40, 50, Colors.blue.withOpacity(0.25), 1),
                    _animatedBubble(
                        MediaQuery.of(context).size.height - 110,
                        -30,
                        80,
                        Colors.yellow.withOpacity(0.25),
                        2),
                    _animatedBubble(
                        MediaQuery.of(context).size.height - 200,
                        -20,
                        60,
                        Colors.blue.withOpacity(0.25),
                        3),
                  ],
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: ListView(
                children: [
                  _buildSectionTitle('إعدادات الحساب'),
                  _buildProfileCard(),

                  const SizedBox(height: 20),
                  _buildSectionTitle('العام'),
                  _buildSettingItem(
                    icon: Icons.language,
                    title: 'اللغة',
                    trailing: DropdownButton<String>(
                      value: language,
                      underline: const SizedBox(),
                      items: ['العربية', 'English'].map((lang) {
                        return DropdownMenuItem(
                          value: lang,
                          child: Text(lang,
                              style: const TextStyle(
                                  fontFamily: 'PlaypenSansArabic')),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => language = value!);
                      },
                    ),
                  ),
                  _buildSwitchItem(
                    icon: Icons.dark_mode,
                    title: 'الوضع الداكن',
                    value: darkMode,
                    onChanged: (val) => setState(() => darkMode = val),
                  ),
                  _buildSwitchItem(
                    icon: Icons.notifications,
                    title: 'الإشعارات',
                    value: notifications,
                    onChanged: (val) => setState(() => notifications = val),
                  ),

                  _buildSwitchItem(
                    icon: Icons.volume_up,
                    title: 'الأصوات',
                    value: sounds,
                    onChanged: (val) async {
                      setState(() => sounds = val);
                      TtsService.setEnabled(val); // مزامنة مع TTS

                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('sounds', val); // 🔹 حفظ دائم
                    },
                  ),



                  const SizedBox(height: 20),
                  _buildSectionTitle('الأمان'),
                  _buildSettingItem(
                    icon: Icons.lock,
                    title: 'تغيير كلمة المرور',
                    onTap: () => _changePasswordDialog(context),
                  ),
                  _buildSettingItem(
                    icon: Icons.logout,
                    title: 'تسجيل الخروج',
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('تأكيد تسجيل الخروج',
                              style: TextStyle(
                                  fontFamily: 'PlaypenSansArabic')),
                          content: const Text(
                            'هل أنت متأكد أنك تريد تسجيل الخروج من حسابك؟',
                            style: TextStyle(
                                fontFamily: 'PlaypenSansArabic'),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('لا',
                                  style: TextStyle(
                                      fontFamily: 'PlaypenSansArabic')),
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                Navigator.pop(context);
                                await _logout();
                              },
                              child: const Text('نعم',
                                  style: TextStyle(
                                      fontFamily: 'PlaypenSansArabic')),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  _buildSettingItem(
                    icon: Icons.delete_forever,
                    title: 'حذف الحساب',
                    onTap: () {
                      final passwordController = TextEditingController();

                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text(
                            'تأكيد حذف الحساب',
                            style: TextStyle(
                              fontFamily: 'PlaypenSansArabic',
                              color: Colors.red,
                            ),
                          ),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'يرجى إدخال كلمة المرور لتأكيد حذف الحساب نهائيًا',
                                style: TextStyle(fontFamily: 'PlaypenSansArabic'),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: passwordController,
                                obscureText: true,
                                decoration: const InputDecoration(
                                  labelText: 'كلمة المرور',
                                ),
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text(
                                'إلغاء',
                                style: TextStyle(fontFamily: 'PlaypenSansArabic'),
                              ),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                              onPressed: () async {
                                final password = passwordController.text.trim();

                                if (password.isEmpty) return;

                                Navigator.pop(context);
                                await _deleteAccount(context, password);
                              },
                              child: const Text(
                                'حذف',
                                style: TextStyle(fontFamily: 'PlaypenSansArabic'),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),



                  const SizedBox(height: 20),
                  _buildSectionTitle('حول التطبيق'),
                  _buildSettingItem(
                    icon: Icons.info,
                    title: 'عن التطبيق',
                    onTap: () => _aboutAppDialog(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= UI Helpers =================

  Widget _animatedBubble(
      double top, double left, double size, Color color, int index) {
    return Positioned(
      top: top + 20 * _controller.value * (index.isEven ? 1 : -1),
      left: left + 10 * _controller.value * (index.isEven ? -1 : 1),
      child: _bubble(size, color),
    );
  }

  Widget _bubble(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontFamily: 'PlaypenSansArabic',
          fontWeight: FontWeight.bold,
          fontSize: 18,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 3,
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.blueAccent,
          child: Icon(Icons.person, color: Colors.white),
        ),
        title: Text(name,
            style: const TextStyle(fontFamily: 'PlaypenSansArabic')),
        subtitle: Text(email,
            style: const TextStyle(fontFamily: 'PlaypenSansArabic')),
        trailing: IconButton(
          icon: const Icon(Icons.edit, color: Colors.yellow),
          onPressed: () => _editProfileDialog(context),
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.yellow.shade700),
      title:
      Text(title, style: const TextStyle(fontFamily: 'PlaypenSansArabic')),
      trailing: trailing ??
          const Icon(Icons.arrow_forward_ios,
              color: Colors.blueAccent, size: 18),
      onTap: onTap,
    );
  }

  Widget _buildSwitchItem({
    required IconData icon,
    required String title,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return SwitchListTile(
      secondary: Icon(icon, color: Colors.yellow.shade700),
      title:
      Text(title, style: const TextStyle(fontFamily: 'PlaypenSansArabic')),
      value: value,
      activeColor: Colors.blueAccent,
      onChanged: onChanged,
    );
  }

  // ================= Dialogs =================



  void _changePasswordDialog(BuildContext context) {
    TextEditingController newPass = TextEditingController();
    TextEditingController confirmPass = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تغيير كلمة المرور',
            style: TextStyle(fontFamily: 'PlaypenSansArabic')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: newPass,
              obscureText: true,
              decoration:
              const InputDecoration(labelText: 'كلمة المرور الجديدة'),
            ),
            TextField(
              controller: confirmPass,
              obscureText: true,
              decoration:
              const InputDecoration(labelText: 'تأكيد كلمة المرور'),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('إلغاء',
                style: TextStyle(fontFamily: 'PlaypenSansArabic')),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            onPressed: () async {
              if (newPass.text == confirmPass.text &&
                  newPass.text.length >= 6) {
                await FirebaseAuth.instance.currentUser
                    ?.updatePassword(newPass.text);
                Navigator.pop(context);
              }
            },
            child: const Text('حفظ',
                style: TextStyle(fontFamily: 'PlaypenSansArabic')),
          ),
        ],
      ),
    );
  }

  void _aboutAppDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حول التطبيق',
            style: TextStyle(fontFamily: 'PlaypenSansArabic')),
        content: const Text(
          'هذا التطبيق مخصص لتعليم وترجمة لغة الإشارة بطريقة تفاعلية وسهلة الاستخدام.',
          style: TextStyle(fontFamily: 'PlaypenSansArabic'),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('حسناً',
                style: TextStyle(fontFamily: 'PlaypenSansArabic')),
          ),
        ],
      ),
    );
  }
}
