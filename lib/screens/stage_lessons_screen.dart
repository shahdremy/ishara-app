import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'lesson_flow_screen.dart';

class StageLessonsScreen extends StatelessWidget {
  final String stageId;
  final String levelId;

  StageLessonsScreen({
    required this.stageId,
    this.levelId = "level1",
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return _errorScaffold("الرجاء تسجيل الدخول");
    }
    final uid = user.uid;
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("levels")
          .doc(levelId)
          .collection("stages")
          .doc(stageId)
          .collection("lessons")
          .orderBy("order")
          .snapshots(),
      builder: (context, lessonSnap) {
        if (lessonSnap.hasError) {
          return _errorScaffold("خطأ عند جلب الدروس");
        }

        if (!lessonSnap.hasData) {
          return _loadingScaffold();
        }

        final lessons = lessonSnap.data!.docs;

        if (lessons.isEmpty) {
          return _errorScaffold("لا توجد دروس في هذه المرحلة");
        }

        return FutureBuilder<QuerySnapshot>(
          future: FirebaseFirestore.instance
              .collection("users")
              .doc(uid)
              .collection("progress")
              .get(),
          builder: (context, progressSnap) {
            if (!progressSnap.hasData) {
              return _loadingScaffold();
            }

            final Map<String, Map<String, dynamic>> progress = {
              for (var d in progressSnap.data!.docs)
                d.id: (d.data() as Map<String, dynamic>? ?? {})
            };

            // 🔹 نحدد آخر درس مكتمل
            int startLessonIndex = 0;

            for (int i = 0; i < lessons.length; i++) {
              final lessonKey =
                  "${levelId}_${stageId}_${lessons[i].id}";

              if (progress[lessonKey]?['completed'] == true) {
                startLessonIndex = i + 1;
              }
            }

            if (startLessonIndex >= lessons.length) {
              startLessonIndex = lessons.length - 1;
            }

            return Scaffold(
              backgroundColor: Colors.white,
              appBar: AppBar(
                title: Text(
                  "الدروس",
                  style: TextStyle(
                    fontFamily: 'PlaypenSansArabic',
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                backgroundColor: Color(0xFFFACC15),
                iconTheme: IconThemeData(color: Colors.black87),
                centerTitle: true,
              ),
              body: ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: lessons.length,
                itemBuilder: (context, i) {
                  final lesson = lessons[i];
                  final lessonKey =
                      "${levelId}_${stageId}_${lesson.id}";

                  final unlocked = i <= startLessonIndex;
                  final completed =
                      progress[lessonKey]?['completed'] == true;

                  return Card(
                    margin: EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(
                        color: unlocked
                            ? Color(0xFF5BC0EB)
                            : Colors.grey.shade300,
                        width: 2,
                      ),
                    ),
                    elevation: 3,
                    child: ListTile(
                      title: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          (lesson.data() as Map<String, dynamic>)['name']?.toString() ?? "درس",
                          style: TextStyle(
                            fontFamily: 'PlaypenSansArabic',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: unlocked
                                ? Colors.black87
                                : Colors.black38,
                          ),
                        ),
                      ),
                      trailing: completed
                          ? Icon(Icons.check_circle,
                          color: Colors.green)
                          : unlocked
                          ? Icon(Icons.play_arrow,
                          color: Color(0xFF5BC0EB))
                          : Icon(Icons.lock,
                          color: Colors.grey),
                      onTap: unlocked
                          ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => LessonFlowScreen(
                              stageId: stageId,
                              lessonsSnapshots: lessons,
                              currentLessonIndex: i,
                            ),
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
      },
    );
  }

  Scaffold _loadingScaffold() {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: Text("تحميل...")),
      body: Center(child: CircularProgressIndicator()),
    );
  }

  Scaffold _errorScaffold(String msg) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: Text("الدروس")),
      body: Center(child: Text(msg)),
    );
  }
}
