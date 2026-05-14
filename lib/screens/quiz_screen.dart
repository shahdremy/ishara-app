// ---------------- QuizScreen كامل مع كل الدوال ----------------
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:confetti/confetti.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class QuizScreen extends StatefulWidget {
  final List<Map<String, dynamic>> quizzes;
  final int lessonNumber; // رقم الدرس لعرضه في شاشة النتيجة
  final String progressPath; // المسار في Firestore للتقدم

  QuizScreen({
    required this.quizzes,
    required this.lessonNumber,
    required this.progressPath,
  });

  @override
  _QuizScreenState createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int currentIndex = 0;
  int correctCount = 0;

  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  ConfettiController? _confettiController;

  static const Color accent = Color(0xFFFACC15); // أصفر
  static const Color extra = Color(0xFF38BDF8); // أزرق سماوي

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoController?.dispose();
    _confettiController?.dispose();
    super.dispose();
  }

  void _playPreview(String url) async {
    _chewieController?.pause();
    _chewieController?.dispose();
    _videoController?.dispose();

    _videoController = VideoPlayerController.network(url);
    await _videoController!.initialize();

    _chewieController = ChewieController(
      videoPlayerController: _videoController!,
      autoPlay: true,
      looping: false,
    );

    setState(() {});

    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: Container(
          width: double.infinity,
          height: 320,
          child: Chewie(controller: _chewieController!),
        ),
      ),
    ).then((_) {
      _chewieController?.dispose();
      _videoController?.dispose();
      _chewieController = null;
      _videoController = null;
    });
  }

  Future<void> _saveProgress() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('progress')
          .doc(widget.progressPath); // progressPath = docId فقط

      await docRef.set({
        'completed': true,
        'score': correctCount,
        'attempts': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint("✅ تم حفظ التقدم للدرس: ${widget.progressPath}");
    } catch (e) {
      debugPrint("❌ Error saving progress: $e");
    }
  }


  void _answerQuestion(String selected) {
    final quiz = widget.quizzes[currentIndex];
    final isCorrect = selected == quiz['correctAnswer'];

    if (isCorrect) correctCount++;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Center(
          child: Text(
            isCorrect ? "إجابة صحيحة ✔" : "إجابة خاطئة ❌",
            style: TextStyle(
              fontFamily: 'PlaypenSansArabic',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isCorrect ? Colors.green : Colors.red,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        content: !isCorrect
            ? Text(
          "الإجابة الصحيحة: ${quiz['correctAnswer']}",
          style: TextStyle(
            fontFamily: 'PlaypenSansArabic',
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        )
            : null,
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: accent,
              padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                if (currentIndex < widget.quizzes.length - 1) {
                  currentIndex++;
                } else {
                  currentIndex++; // يخلّيه يدخل شاشة النتيجة
                }
              });
            },
            child: Text(
              currentIndex == widget.quizzes.length - 1
                  ? "إنهاء الاختبار"
                  : "التالي",
              style: TextStyle(fontFamily: 'PlaypenSansArabic'),
            ),

          ),
        ],
      ),
    );
  }

  // ---------------- دوال واجهة الاختبار ----------------
  Widget _buildVideoToWord(Map<String, dynamic> quiz) {
    final videoUrl = quiz['videoUrl'];
    final options = List<String>.from(quiz['options']);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              height: 260,
              color: Colors.black,
              child: VideoPlayerWidget(url: videoUrl),
            ),
          ),
          SizedBox(height: 14),
          Text(
            quiz['question'],
            style: TextStyle(
              fontFamily: 'PlaypenSansArabic',
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 14),
          ...options.map((opt) {
            return Container(
              width: MediaQuery.of(context).size.width * 0.85,
              margin: EdgeInsets.only(bottom: 10),
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => _answerQuestion(opt),
                child: Text(
                  opt,
                  style: TextStyle(
                      fontFamily: 'PlaypenSansArabic',
                      fontSize: 16,
                      color: Colors.black),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildWordToVideo(Map<String, dynamic> quiz) {
    final optionsRaw = quiz['videoOptions'];

    if (optionsRaw == null || optionsRaw is! List) {
      return Center(
        child: Text(
          "خطأ في بيانات السؤال",
          style: TextStyle(
            fontFamily: 'PlaypenSansArabic',
            fontSize: 18,
            color: Colors.red,
          ),
        ),
      );
    }

    final options = List<String>.from(optionsRaw);    final selected = widget.quizzes[currentIndex]['selected'] ?? "";
    bool answered = widget.quizzes[currentIndex]['answered'] ?? false;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        children: [
          Spacer(flex: 2),
          Text(
            quiz['question'],
            style: TextStyle(
              fontFamily: 'PlaypenSansArabic',
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          ...options.map((url) {
            bool isSelected = selected == url;
            bool isCorrect = quiz['correctAnswer'] == url;

            Color cardColor = Colors.white;
            if (answered) {
              if (isCorrect) {
                cardColor = Colors.green.shade300;
              } else if (isSelected && !isCorrect) {
                cardColor = Colors.red.shade300;
              }
            }

            return Card(
              color: cardColor,
              elevation: 3,
              margin: EdgeInsets.symmetric(vertical: 6),
              child: Padding(
                padding: EdgeInsets.all(8),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => _playPreview(url),
                      child: Container(
                        width: 90,
                        height: 70,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: VideoPlayerMini(url: url),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "عرض الفيديو",
                        style: TextStyle(
                            fontFamily: 'PlaypenSansArabic', fontSize: 16),
                      ),
                    ),
                    if (!answered)
                      Checkbox(
                        value: isSelected,
                        activeColor: extra,
                        onChanged: (_) {
                          setState(() {
                            widget.quizzes[currentIndex]['selected'] = url;
                          });
                        },
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
          SizedBox(height: 16),
          if (!answered)
            Container(
              width: MediaQuery.of(context).size.width * 0.7,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  if (selected.isNotEmpty) {
                    setState(() {
                      widget.quizzes[currentIndex]['answered'] = true;
                    });
                    if (selected == quiz['correctAnswer']) correctCount++;
                  }
                },
                child: Text(
                  "تأكيد الإجابة",
                  style: TextStyle(
                      fontFamily: 'PlaypenSansArabic',
                      fontSize: 18,
                      color: Colors.black),
                ),
              ),
            )
          else
            Container(
              width: MediaQuery.of(context).size.width * 0.7,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  setState(() => currentIndex++);
                },
                child: Text(
                  currentIndex == widget.quizzes.length - 1
                      ? "إنهاء الاختبار"
                      : "التالي",
                  style: TextStyle(
                    fontFamily: 'PlaypenSansArabic',
                    fontSize: 18,
                    color: Colors.black,
                  ),
                ),

              ),
            ),
          Spacer(flex: 3),
        ],
      ),
    );
  }

  // ---------------- build ----------------
  @override
  Widget build(BuildContext context) {
    
    if (currentIndex >= widget.quizzes.length) {
      int total = widget.quizzes.length;
      double percent = total == 0 ? 0 : (correctCount / total) * 100;
      bool success = percent >= 50;

      if (success) _confettiController?.play();

      return Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController!,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                colors: const [
                  Colors.red,
                  Colors.blue,
                  Colors.green,
                  Colors.yellow,
                  Colors.orange,
                  Colors.purple
                ],
                numberOfParticles: 30,
                gravity: 0.3,
              ),
            ),
            Directionality(
              textDirection: TextDirection.rtl,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      success ? Icons.celebration : Icons.info,
                      size: 120,
                      color: Colors.blueAccent,
                    ),
                    SizedBox(height: 20),
                    Text(
                      success
                          ? "مبروك! تم اجتياز الدرس ${widget.lessonNumber} "
                          : "انتهى الاختبار!",
                      style: TextStyle(
                        fontFamily: 'PlaypenSansArabic',
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 16),
                    Text(
                      "نتيجتك: ${percent.toInt()}%",
                      style: TextStyle(
                        fontFamily: 'PlaypenSansArabic',
                        fontSize: 22,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 30),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        padding:
                        EdgeInsets.symmetric(horizontal: 35, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        await _saveProgress();

                        if (!mounted) return;
                        Navigator.pop(context, true); // نرجّع نتيجة فقط
                      },


                      child: Text(
                        "إنهاء",
                        style: TextStyle(
                          fontFamily: 'PlaypenSansArabic',
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    final quiz = widget.quizzes[currentIndex];
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: EdgeInsets.all(16),
        child: quiz['type'] == "video_to_word"
            ? _buildVideoToWord(quiz)
            : _buildWordToVideo(quiz),
      ),
    );
  }
}

// ---------------- Video Player Widgets ---------------------
class VideoPlayerWidget extends StatefulWidget {
  final String url;
  VideoPlayerWidget({required this.url});

  @override
  _VideoPlayerWidgetState createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  VideoPlayerController? controller;

  @override
  void initState() {
    super.initState();
    controller = VideoPlayerController.network(widget.url)
      ..initialize().then((_) {
        setState(() {});
        controller!.play();
      });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return controller != null && controller!.value.isInitialized
        ? VideoPlayer(controller!)
        : Center(child: CircularProgressIndicator());
  }
}

class VideoPlayerMini extends StatefulWidget {
  final String url;
  VideoPlayerMini({required this.url});

  @override
  _VideoPlayerMiniState createState() => _VideoPlayerMiniState();
}

class _VideoPlayerMiniState extends State<VideoPlayerMini> {
  VideoPlayerController? controller;

  @override
  void initState() {
    super.initState();
    controller = VideoPlayerController.network(widget.url)
      ..initialize().then((_) {
        setState(() {});
      });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return controller != null && controller!.value.isInitialized
        ? VideoPlayer(controller!)
        : Center(child: Icon(Icons.play_arrow, color: Colors.white));
  }
}
