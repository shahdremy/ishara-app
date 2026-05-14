import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class ArchiveScreen extends StatefulWidget {
  const ArchiveScreen({Key? key}) : super(key: key);

  @override
  State<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends State<ArchiveScreen> {
  final String mainFont = 'PlaypenSansArabic';
  final Color primaryYellow = const Color(0xFFFACC15);
  final Color primaryBlue = const Color(0xFF5BC0EB);

  String searchQuery = '';

  void _openVideoDialog(BuildContext context, String url) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => VideoDialog(
        videoUrl: url,
        primaryYellow: primaryYellow,
        mainFont: mainFont,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryYellow,
        elevation: 0,
        title: Text(
          "أرشيف الإشارات",
          style: TextStyle(
            fontFamily: mainFont,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.star_rounded,
              color: Colors.black,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const FavoritesArchiveScreen(),
                ),
              );
            },
          ),
        ],
      ),

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              textAlign: TextAlign.end,
              onChanged: (v) => setState(() => searchQuery = v),
              decoration: InputDecoration(
                hintText: "ابحث عن إشارة",
                prefixIcon: const Icon(Icons.search),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade400),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: primaryBlue, width: 2),
                ),
              ),
            ),
          ),
          // 📚 القائمة
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .collection('archive')
                  .orderBy('completedAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      "لا يوجد إشارات ",
                      style: TextStyle(fontFamily: mainFont, fontSize: 18),
                    ),
                  );
                }

                final docs = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = data['name'] ?? '';
                  final translation = data['translation'] ?? '';

                  return name.contains(searchQuery) ||
                      translation.contains(searchQuery);
                }).toList();

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final videoUrl = data['videoUrl'] ?? '';
                    final isFavorite = data['favorite'] == true;

                    return Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: primaryBlue, width: 2),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 6,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),

                        child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                    if (videoUrl.isNotEmpty) {
                    _openVideoDialog(context, videoUrl);
                    }
                    },
                    child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                    children: [
                    // 🎥 فيديو صغير
                    ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: SizedBox(
                    width: 100,
                    height: 70,
                    child: VideoThumbnail(
                    videoUrl: videoUrl,
                    primaryYellow: primaryYellow,
                    ),
                    ),
                    ),
                    const SizedBox(width: 12),

                    // 📝 النصوص
                    Expanded(
                    child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                    Text(
                    data['name'] ?? '',
                    textAlign: TextAlign.end,
                    style: TextStyle(
                    fontFamily: mainFont,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                    data['translation'] ?? '',
                    textAlign: TextAlign.end,
                    style: TextStyle(
                    fontFamily: mainFont,
                    fontSize: 14,
                    color: Colors.black54,
                    ),
                    ),
                    ],
                    ),
                    ),

                    // ⭐ مفضلة
                    IconButton(
                    icon: Icon(
                    isFavorite
                    ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    color: primaryYellow,
                    ),
                    onPressed: () {
                    doc.reference.update({
                    'favorite': !isFavorite,
                    });
                    },
                    ),
                    ],
                    ),
                    ),
                    ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

//////////////////////////////////////////////////////////////
/// 🎥 فيديو صغير داخل الكارد (مع Loading)
//////////////////////////////////////////////////////////////
class VideoThumbnail extends StatefulWidget {
  final String videoUrl;
  final Color primaryYellow;

  const VideoThumbnail({
    Key? key,
    required this.videoUrl,
    required this.primaryYellow,
  }) : super(key: key);

  @override
  State<VideoThumbnail> createState() => _VideoThumbnailState();
}

class _VideoThumbnailState extends State<VideoThumbnail> {
  VideoPlayerController? _controller;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    if (widget.videoUrl.isEmpty) return;

    _controller = VideoPlayerController.network(widget.videoUrl);
    await _controller!.initialize();
    _controller!.setVolume(0);
    _controller!.play();

    setState(() => loading = false);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Center(
        child: CircularProgressIndicator(
          color: widget.primaryYellow,
          strokeWidth: 2,
        ),
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        AspectRatio(
          aspectRatio: _controller!.value.aspectRatio,
          child: VideoPlayer(_controller!),
        ),
        const Icon(
          Icons.play_circle_fill_rounded,
          color: Colors.white,
          size: 32,
        ),
      ],
    );
  }
}
class FavoritesArchiveScreen extends StatelessWidget {
  const FavoritesArchiveScreen({super.key});

  final String mainFont = 'PlaypenSansArabic';
  final Color primaryYellow = const Color(0xFFFACC15);
  final Color primaryBlue = const Color(0xFF5BC0EB);

  void _openVideoDialog(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (_) => VideoDialog(
        videoUrl: url,
        primaryYellow: primaryYellow,
        mainFont: mainFont,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            "المفضلة ⭐",
            style: TextStyle(
              fontFamily: mainFont,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          backgroundColor: primaryYellow,
          centerTitle: true,
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('archive')
              .where('favorite', isEqualTo: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Text(
                  "لا توجد إشارات مفضلة",
                  style: TextStyle(fontFamily: mainFont, fontSize: 18),
                ),
              );
            }

            final docs = snapshot.data!.docs;

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final doc = docs[index];
                final data = doc.data() as Map<String, dynamic>;
                final videoUrl = data['videoUrl'] ?? '';

                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: primaryBlue, width: 2),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      if (videoUrl.isNotEmpty) {
                        _openVideoDialog(context, videoUrl);
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          // ⭐ زر المفضلة
                          IconButton(
                            icon: const Icon(
                              Icons.star_rounded,
                              color: Color(0xFFFACC15),
                            ),
                            onPressed: () {
                              doc.reference.update({'favorite': false});
                            },
                          ),

                          // 📝 النص
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  data['name'] ?? '',
                                  textAlign: TextAlign.end,
                                  style: TextStyle(
                                    fontFamily: mainFont,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  data['translation'] ?? '',
                                  textAlign: TextAlign.end,
                                  style: TextStyle(
                                    fontFamily: mainFont,
                                    fontSize: 14,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 12),

                          // 🎥 الفيديو
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: SizedBox(
                              width: 100,
                              height: 70,
                              child: VideoThumbnail(
                                videoUrl: videoUrl,
                                primaryYellow: primaryYellow,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

//////////////////////////////////////////////////////////////
/// 📺 Dialog الفيديو الكامل
//////////////////////////////////////////////////////////////
class VideoDialog extends StatefulWidget {
  final String videoUrl;
  final Color primaryYellow;
  final String mainFont;

  const VideoDialog({
    Key? key,
    required this.videoUrl,
    required this.primaryYellow,
    required this.mainFont,
  }) : super(key: key);

  @override
  State<VideoDialog> createState() => _VideoDialogState();
}

class _VideoDialogState extends State<VideoDialog> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    _videoController = VideoPlayerController.network(widget.videoUrl);
    await _videoController!.initialize();

    _chewieController = ChewieController(
      videoPlayerController: _videoController!,
      autoPlay: true,
      looping: false,
      allowFullScreen: true,
      showControls: true,
      materialProgressColors: ChewieProgressColors(
        playedColor: widget.primaryYellow,
        handleColor: widget.primaryYellow,
        backgroundColor: Colors.grey.shade300,
        bufferedColor: Colors.grey.shade400,
      ),
    );

    setState(() => loading = false);
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        child: loading
            ? Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              color: widget.primaryYellow,
            ),
            const SizedBox(height: 12),
            Text(
              "جارٍ تحميل الفيديو...",
              style: TextStyle(fontFamily: widget.mainFont),
            ),
          ],
        )
            : AspectRatio(
          aspectRatio: _videoController!.value.aspectRatio,
          child: Chewie(controller: _chewieController!),
        ),
      ),
    );
  }
}