import 'package:flutter/material.dart';
import 'package:ishara/screens/translate_screen.dart';
import 'package:ishara/screens/learning_screen.dart';
import 'package:ishara/screens/settings_screen.dart';
import 'package:ishara/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;


  final List<Widget> _screens =  [
    TranslateScreen(),
    LearningScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _checkGeneralInactivity();
  }

  Future<void> _checkGeneralInactivity() async {
    final prefs = await SharedPreferences.getInstance();
    final lastOpen = prefs.getInt('last_open') ?? 0;

    final now = DateTime.now().millisecondsSinceEpoch;
    final diffDays = (now - lastOpen) ~/ (1000 * 60 * 60 * 24);

    if (diffDays >= 2) {
      NotificationService.show(
        id: 10,
        title: '🌟 اشتقنالك',
        body: 'كمّل رحلتك في تعلّم لغة الإشارة اليوم ',
      );
    }

    await prefs.setInt('last_open', now);
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  final Color yellowLight = const Color(0xFFFFE066);
  final Color yellowDark = const Color(0xFFFFC107);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(65),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(25),
            bottomRight: Radius.circular(25),
          ),
          child: AppBar(
            elevation: 5,
            centerTitle: true,
            automaticallyImplyLeading: false,
            title: const Text(
              "إشارة",
              style: TextStyle(
                fontFamily: "PlaypenSansArabic",
                fontSize: 26,
                color: Colors.black,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFFFE066),
                    Color(0xFFFFD43B),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
        ),
      ),

      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        transitionBuilder: (child, animation) =>
            FadeTransition(opacity: animation, child: child),
        child: _screens[_selectedIndex],
      ),

      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(left: 12, right: 12, bottom: 10),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12.withOpacity(0.15),
                  blurRadius: 8,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: BottomNavigationBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              type: BottomNavigationBarType.fixed,
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
              showSelectedLabels: false,
              showUnselectedLabels: false,
              selectedItemColor: yellowDark,
              unselectedItemColor: yellowLight,
              items: [
                _buildNavItem(Icons.pan_tool_alt_rounded, 0),
                _buildNavItem(Icons.school_rounded, 1),
                _buildNavItem(Icons.settings_rounded, 2),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 🔸 دالة تبني أيقونة القائمة السفلية وتضيف الخط الأصفر أسفل المختارة
  BottomNavigationBarItem _buildNavItem(IconData icon, int index) {
    bool isSelected = _selectedIndex == index;
    return BottomNavigationBarItem(
      label: '',
      icon: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 30, color: isSelected ? yellowDark : yellowLight),
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.only(top: 4),
            height: 3,
            width: isSelected ? 20 : 0,
            decoration: BoxDecoration(
              color: isSelected ? yellowDark : Colors.transparent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}
