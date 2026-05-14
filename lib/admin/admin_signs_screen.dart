import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminSignsScreen extends StatelessWidget {
  final String levelId;
  final String stageId;
  final String lessonId;

  const AdminSignsScreen({
    super.key,
    required this.levelId,
    required this.stageId,
    required this.lessonId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إدارة الإشارات')),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          await FirebaseFirestore.instance
              .collection('levels')
              .doc(levelId)
              .collection('stages')
              .doc(stageId)
              .collection('lessons')
              .doc(lessonId)
              .collection('signs')
              .add({
            'word': 'كلمة جديدة',
            'videoUrl': '',
          });
        },
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('levels')
            .doc(levelId)
            .collection('stages')
            .doc(stageId)
            .collection('lessons')
            .doc(lessonId)
            .collection('signs')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView(
            children: snapshot.data!.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return ListTile(
                title: Text(data['word']),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    await doc.reference.delete();
                  },
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
