import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'stage_lessons_screen.dart';

class LevelStagesScreen extends StatefulWidget {
  final String levelId;
  final String levelName;

  LevelStagesScreen({required this.levelId, required this.levelName});

  @override
  State<LevelStagesScreen> createState() => _LevelStagesScreenState();
}

class _LevelStagesScreenState extends State<LevelStagesScreen> {
  final List<String> stageImages = [
    "assets/images/wired-flat-2716-logo-clubhouse-hover-pinch.png",
    "assets/images/wired-flat-21-avatar-hover-jumping.png",
    "assets/images/wired-flat-970-video-conference-hover-pinch.png",
    "assets/images/wired-flat-646-walking-walkcycle-person-hover-walking.png",
    "assets/images/wired-flat-63-home-hover-3d-roll.png",
  ];

  Map<String, dynamic> stageProgress = {};
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _fetchStageProgress();
  }

  Future<void> _fetchStageProgress() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('progress')
          .doc('learning')
          .get();

      if (doc.exists && doc.data() != null) {
        stageProgress = doc.data()!;
      } else {
        stageProgress = {};
      }

      setState(() {
        loading = false;
      });
    } catch (e) {
      print("Error fetching stage progress: $e");
      setState(() {
        stageProgress = {};
        loading = false;
      });
    }
  }

  bool _isStageUnlocked(int index) {
    if (index == 0) return true; // أول مرحلة مفتوحة دائمًا

    final stageKey = "${widget.levelId}_stage${index + 1}";
    return stageProgress[stageKey]?['unlocked'] == true;
  }

  @override
  Widget build(BuildContext context) {
    // شاشة اللود تكون فقط CircularProgressIndicator
    if (loading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(widget.levelName,
              style: TextStyle(
                  fontFamily: 'PlaypenSansArabic',
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87)),
          backgroundColor: Color(0xFFFACC15),
          iconTheme: IconThemeData(color: Colors.black87),
          centerTitle: true,
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // بعد التحميل: واجهة المراحل بيضاء كما هي
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("levels")
          .doc(widget.levelId)
          .collection("stages")
          .orderBy("order")
          .snapshots(),
      builder: (context, snap) {
        if (snap.hasError) return Center(child: Text("خطأ في تحميل المراحل"));
        if (!snap.hasData) return Center(child: CircularProgressIndicator());

        final stages = snap.data!.docs;
        if (stages.isEmpty) return Center(child: Text("لا توجد مراحل"));

        final stageNames = [
          "المرحلة الأولى",
          "المرحلة الثانية",
          "المرحلة الثالثة",
          "المرحلة الرابعة",
          "المرحلة الخامسة"
        ];

        return Scaffold(
          backgroundColor: Colors.white, // خلفية الواجهة بيضاء
          appBar: AppBar(
            title: Text(widget.levelName,
                style: TextStyle(
                    fontFamily: 'PlaypenSansArabic',
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87)),
            backgroundColor: Color(0xFFFACC15),
            iconTheme: IconThemeData(color: Colors.black87),
            centerTitle: true,
            elevation: 4,
          ),
          body: ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: stages.length,
            itemBuilder: (context, i) {
              final doc = stages[i];
              final stageName = stageNames[i % stageNames.length];
              final unlocked = _isStageUnlocked(i);

              return Card(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Color(0xFF5BC0EB), width: 2),
                ),
                margin: EdgeInsets.only(bottom: 16),
                elevation: 3,
                child: ListTile(
                  leading: Image.asset(
                    stageImages[i % stageImages.length],
                    width: 50,
                    height: 50,
                    fit: BoxFit.contain,
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  title: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      stageName,
                      style: TextStyle(
                        fontFamily: 'PlaypenSansArabic',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: unlocked ? Colors.black87 : Colors.black38,
                      ),
                    ),
                  ),
                  subtitle: Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 6.0),
                      child: Text(
                        doc['name'] ?? '',
                        style: TextStyle(
                          fontFamily: 'PlaypenSansArabic',
                          fontSize: 16,
                          color: unlocked ? Colors.black87 : Colors.black38,
                        ),
                      ),
                    ),
                  ),
                  onTap: unlocked
                      ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            StageLessonsScreen(stageId: doc.id),
                      ),
                    );
                  }
                      : null,
                ),
              );
            },
          ),
        );
      },
    );
  }
}
