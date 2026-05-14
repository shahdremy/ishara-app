import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ishara/services/notification_service.dart';
import 'level_stages_screen.dart';
import 'archive_screen.dart';

class LearningScreen extends StatefulWidget {
  @override
  State<LearningScreen> createState() => _LearningScreenState();
}

class _LearningScreenState extends State<LearningScreen> {
  final Color primaryYellow = Color(0xFFFACC15);
  final Color primarySkyBlue = Color(0xFF5BC0EB);
  final Color textBlack = Colors.black87;
  final String mainFont = 'PlaypenSansArabic';

  bool loading = true;
  bool level1Unlocked = true;
  int level1Stars = 0;

  @override
  void initState() {
    super.initState();
    _fetchUserProgress();

  }


  Future<void> _fetchUserProgress() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final progressSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('progress')
          .get();

      int completedLessons = 0;

      for (final doc in progressSnap.docs) {
        final data = doc.data();
        if (doc.id.startsWith('level1_') && data['completed'] == true) {
          completedLessons++;
        }
      }

      const int totalLessonsLevel1 = 20;
      int stars =
      ((completedLessons / totalLessonsLevel1) * 3).round().clamp(0, 3);

      setState(() {
        level1Unlocked = true;
        level1Stars = stars;
        loading = false;
      });
    } catch (e) {
      setState(() {
        loading = false;
        level1Unlocked = true;
        level1Stars = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(color: primaryYellow),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 📘 المستويات
              _buildLevelCard("المستوى الأول", level1Unlocked, level1Stars),
              _buildLevelCard("المستوى الثاني", false, 0),
              _buildLevelCard("المستوى الثالث", false, 0),

              SizedBox(height: 12),

              // 🗂 كارد الأرشيف
              _buildArchiveCard(context),

              SizedBox(height: 40), // مهم للسكرول
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLevelCard(String name, bool unlocked, int stars) {
    return Container(
      margin: EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primarySkyBlue, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 3),
          )
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: unlocked
            ? () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  LevelStagesScreen(levelId: "level1", levelName: name),
            ),
          );
        }
            : null,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 16, horizontal: 14),
          child: Row(
            children: [
              Container(
                width: 6,
                height: 70,
                decoration: BoxDecoration(
                  color: primarySkyBlue,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              SizedBox(width: 14),
              Expanded(
                child: Column(

                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontFamily: mainFont,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color:
                        unlocked ? textBlack : textBlack.withOpacity(0.4),
                      ),
                    ),
                    SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: List.generate(
                        3,
                            (i) => Icon(
                          i < stars ? Icons.star : Icons.star_border,
                          color: primaryYellow,
                          size: 20,
                        ),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      unlocked ? "ابدأ التعلم" : "تحت التطوير 🔒",
                      style: TextStyle(
                        fontFamily: mainFont,
                        fontSize: 15,
                        color: unlocked
                            ? textBlack.withOpacity(0.7)
                            : textBlack.withOpacity(0.4),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8),
              Icon(
                unlocked ? Icons.school_rounded : Icons.lock,
                color:
                unlocked ? primarySkyBlue : textBlack.withOpacity(0.3),
                size: 28,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildArchiveCard(BuildContext context) {
    final mq = MediaQuery.of(context);
    final width = mq.size.width;

    // حجم الكارد يتغير حسب حجم الشاشة
    final cardHeight = width > 600 ? 90.0 : 80.0;
    final iconSize = width > 600 ? 32.0 : 28.0;

    return Container(
      decoration: BoxDecoration(
        color: Color(0xFFFFF3D9), // 🌟 لون مختلف شوي عن كروت المستويات
        borderRadius: BorderRadius.circular(20), // أكثر انحناء لتوضيح أنه مختلف
        border: Border.all(color: primarySkyBlue, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black26, // ظل أغمق قليلاً ليبرز
            blurRadius: 8,
            offset: Offset(0, 4),
          )
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ArchiveScreen()),
          );
        },
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          child: Row(
            children: [
              Container(
                width: 8,
                height: cardHeight - 20,
                decoration: BoxDecoration(
                  color: primarySkyBlue,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "أرشيف الإشارات",
                      style: TextStyle(
                        fontFamily: mainFont,
                        fontSize: width > 600 ? 20 : 18,
                        fontWeight: FontWeight.bold,
                        color: textBlack,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      "الإشارات التي تم دراستها",
                      style: TextStyle(
                        fontFamily: mainFont,
                        fontSize: width > 600 ? 16 : 14,
                        color: textBlack.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.archive_rounded,
                color: primarySkyBlue,
                size: iconSize,
              ),
            ],
          ),
        ),
      ),
    );
  }

}