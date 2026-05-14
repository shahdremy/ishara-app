import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ishara/services/notification_service.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'quiz_screen.dart';

class LessonFlowScreen extends StatefulWidget {
  final String stageId;
  final List<QueryDocumentSnapshot<Object?>> lessonsSnapshots;
  final int currentLessonIndex;


  LessonFlowScreen({
    required this.stageId,
    required this.lessonsSnapshots,
    required this.currentLessonIndex,
  });

  @override
  _LessonFlowScreenState createState() => _LessonFlowScreenState();
}

class _LessonFlowScreenState extends State<LessonFlowScreen> {
  List<QueryDocumentSnapshot<Object?>> signs = [];
  int signIndex = 0;

  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _loadingSigns = true;
  bool _videoInitializing = false;

  final Color primaryYellow = Color(0xFFFACC15);
  final String mainFont = 'PlaypenSansArabic';

  final uid = FirebaseAuth.instance.currentUser?.uid;

  QueryDocumentSnapshot<Object?> get currentLessonDoc {
    if (widget.currentLessonIndex < 0 ||
        widget.currentLessonIndex >= widget.lessonsSnapshots.length) {
      return widget.lessonsSnapshots.first;
    }
    return widget.lessonsSnapshots[widget.currentLessonIndex];
  }

  String get progressKey =>
      "level1_${widget.stageId}_${currentLessonDoc.id}";

  @override
  void initState() {
    super.initState();
    _loadSigns();

  }

  @override
  void dispose() {
    // لو ما كملش آخر درس
    NotificationService.show(
      id: 102,
      title: '📘 تذكير',
      body: 'ما تنساش تكمل درسك في لغة الإشارة 👋',
    );
    // تحفيز على الرجوع للتعلّم
    NotificationService.show(
      id: 12,
      title: '📘 خطوة صغيرة',
      body: 'إشارة واحدة اليوم تفرّق، كمّل تعلّمك 👋',
    );
    _disposeVideo();
    super.dispose();
  }

  void _disposeVideo() {
    _chewieController?.dispose();
    _chewieController = null;
    _videoController?.dispose();
    _videoController = null;
  }

  Future<void> _initializeVideo(String url, {bool autoPlay = true}) async {
    _disposeVideo();
    setState(() => _videoInitializing = true);

    try {
      _videoController = VideoPlayerController.network(url);
      await _videoController!.initialize();
      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: autoPlay,
        looping: false,
        allowFullScreen: true,
        showControls: true,
        aspectRatio: _videoController!.value.aspectRatio,
        materialProgressColors: ChewieProgressColors(
          playedColor: primaryYellow,
          handleColor: primaryYellow,
          backgroundColor: Colors.grey.shade300,
          bufferedColor: Colors.grey.shade400,
        ),
      );
    } catch (e) {
      _disposeVideo();
    } finally {
      setState(() => _videoInitializing = false);
    }
  }

  Future<void> _loadSigns() async {
    setState(() => _loadingSigns = true);
    int _previousSignsCount = 0;
    final lessonId = currentLessonDoc.id;
    final q = await FirebaseFirestore.instance
        .collection("levels")
        .doc("level1")
        .collection("stages")
        .doc(widget.stageId)
        .collection("lessons")
        .doc(lessonId)
        .collection("signs")
        .orderBy("order")
        .get();



    signs = q.docs;
    _previousSignsCount = signs.length;

    if (signs.isNotEmpty) {
      final url =
      (signs[0].data() as Map<String, dynamic>)['vid_url'] as String?;
      if (url != null && url.isNotEmpty) await _initializeVideo(url);
    }

    setState(() => _loadingSigns = false);
  }


  Future<void> _onNextPressed() async {

    if (signIndex < signs.length - 1) {
      setState(() => signIndex++);
      final url =
      (signs[signIndex].data() as Map<String, dynamic>)['vid_url'] as String?;
      if (url != null && url.isNotEmpty)
        await _initializeVideo(url);
      else
        _disposeVideo();
    } else {
      final lessonId = currentLessonDoc.id;
      List<Map<String, dynamic>> aggregated = [];

      for (final s in signs) {
        final qsnap = await FirebaseFirestore.instance
            .collection("levels")
            .doc("level1")
            .collection("stages")
            .doc(widget.stageId)
            .collection("lessons")
            .doc(lessonId)
            .collection("signs")
            .doc(s.id)
            .collection("quizzes")
            .get();

        for (final doc in qsnap.docs) {
          final data = doc.data();
          if (data.containsKey('quizzes') && data['quizzes'] is List) {
            for (final q in data['quizzes']) {
              if (q is Map<String, dynamic>)
                aggregated.add(q);
              else if (q is Map) aggregated.add(Map<String, dynamic>.from(q));
            }
          }
        }
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final uid = user.uid;
      final progressKey = "level1_${widget.stageId}_${currentLessonDoc.id}";

      final finished = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => QuizScreen(
            quizzes: aggregated,
            lessonNumber: widget.currentLessonIndex + 1,
            progressPath: progressKey, // docId فقط
          ),
        ),
      );

      if (finished == true) {
        await _onFinishLesson();
      }


    }
  }

  Future<void> _onFinishLesson() async {
    if (uid == null) return;

    final progressRef = FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .collection("progress")
        .doc(progressKey);

    await progressRef.set({
      'completed': true,
      'attempts': FieldValue.increment(1),
    }, SetOptions(merge: true));

    await _addLessonToArchive();

    final currentIndex = widget.currentLessonIndex;

    // ✅ لو فيه درس بعده → نفتح الدرس التالي
    if (currentIndex < widget.lessonsSnapshots.length - 1) {
      final nextDoc = widget.lessonsSnapshots[currentIndex + 1];

      final nextProgressKey = "level1_${widget.stageId}_${nextDoc.id}";

      final nextRef = FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .collection("progress")
          .doc("learning")
          .collection("lessons")
          .doc(nextProgressKey);

      await nextRef.set({'unlocked': true}, SetOptions(merge: true));
      // 👇 إشعار فتح درس
      NotificationService.show(
        id: 101,
        title: '📘 درس جديد',
        body: 'تم فتح درس جديد، كمل التعلّم 👋',
      );


      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => LessonFlowScreen(
            stageId: widget.stageId,
            lessonsSnapshots: widget.lessonsSnapshots,
            currentLessonIndex: currentIndex + 1,
          ),
        ),
      );
    }
    // ✅ لو هذا آخر درس → نفتح المرحلة التالية
    else {
      final nextStageIndex =
          int.parse(widget.stageId.replaceAll('stage', '')) + 1;

      final nextStageKey = "level1_stage$nextStageIndex";

      await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .collection("progress")
          .doc("learning")
          .set({
        nextStageKey: {'unlocked': true}
      }, SetOptions(merge: true));

      // 👇👇👇 هنا الإشعار
      NotificationService.show(
        id: 100,
        title: '🎉 مرحلة جديدة!',
        body: 'مبروك! فتحت مرحلة جديدة في ${widget.stageId}',
      );

      // الرجوع لقائمة المراحل
      Navigator.popUntil(context, (route) => route.isFirst);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("🎉 تم فتح المرحلة التالية")),
      );
    }
  }

  Future<void> _addLessonToArchive() async {
    if (uid == null) return;

    final lessonId = currentLessonDoc.id;

    final signsSnap = await FirebaseFirestore.instance
        .collection("levels")
        .doc("level1")
        .collection("stages")
        .doc(widget.stageId)
        .collection("lessons")
        .doc(lessonId)
        .collection("signs")
        .get();

    final batch = FirebaseFirestore.instance.batch();

    for (final signDoc in signsSnap.docs) {
      final data = signDoc.data();

      // ✅ نفس ID الإشارة
      final archiveRef = FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .collection("archive")
          .doc(signDoc.id);

      final existing = await archiveRef.get();

      // ✅ لو مش موجود → نضيفه
      if (!existing.exists) {
        batch.set(archiveRef, {
          'name': data['name'] ?? '',
          'translation': data['translation'] ?? '',
          'videoUrl': data['vid_url'] ?? '',
          'levelId': 'level1',
          'stageId': widget.stageId,
          'lessonId': lessonId,
          'completedAt': FieldValue.serverTimestamp(),
          'favorite': false,
        });
      }
    }

    await batch.commit();
  }


  @override
  Widget build(BuildContext context) {
    if (_loadingSigns) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: primaryYellow,
          title: Align(
            alignment: Alignment.centerRight,
            child: Text(
              currentLessonDoc['name'] ?? "درس",
              style: TextStyle(
                fontFamily: mainFont,
                color: Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (signs.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: primaryYellow,
          title: Align(
            alignment: Alignment.centerRight,
            child: Text(
              currentLessonDoc['name'] ?? "درس",
              style: TextStyle(
                fontFamily: mainFont,
                color: Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        body: Center(child: Text("لا توجد إشارات لعرضها في هذا الدرس")),
      );
    }

    final sign = signs[signIndex];
    final signData = sign.data() as Map<String, dynamic>? ?? {};
    final vid = signData['vid_url']?.toString() ?? '';
    final isLastSign = signIndex == signs.length - 1;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryYellow,
        title: Align(
          alignment: Alignment.centerRight,
          child: Text(
            currentLessonDoc['name'] ?? "درس",
            style: TextStyle(
              fontFamily: mainFont,
              color: Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          if (_videoInitializing)
            Container(
              height: 250,
              child: Center(child: CircularProgressIndicator()),
            )
          else
            vid.isNotEmpty && _chewieController != null
                ? AspectRatio(
              aspectRatio: _videoController?.value.aspectRatio ?? 16 / 9,
              child: Chewie(controller: _chewieController!),
            )
                : Container(
              height: 250,
              color: Colors.black,
              child: Center(
                child: Text(
                  "لا يوجد فيديو لهذه الإشارة",
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: mainFont,
                  ),
                ),
              ),
            ),
          SizedBox(height: 12),
          if (signData['name'] != null)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              margin: EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                signData['name'],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  fontFamily: mainFont,
                ),
              ),
            ),
          Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (signIndex > 0)
                  OutlinedButton(
                    onPressed: () async {
                      if (signIndex > 0) {
                        setState(() => signIndex--);
                        final url = (signs[signIndex].data()
                        as Map<String, dynamic>)['vid_url'] as String?;
                        if (url != null && url.isNotEmpty)
                          await _initializeVideo(url);
                        else
                          _disposeVideo();
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: primaryYellow, width: 2),
                    ),
                    child: Text(
                      "السابق",
                      style: TextStyle(
                        fontFamily: mainFont,
                        color: primaryYellow,
                      ),
                    ),
                  )
                else
                  SizedBox(width: 100),
                ElevatedButton(
                  onPressed: _onNextPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryYellow,
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  ),
                  child: Text(
                    isLastSign ? "ابدأ الاختبار" : "التالي",
                    style: TextStyle(
                      fontSize: 18,
                      fontFamily: mainFont,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
