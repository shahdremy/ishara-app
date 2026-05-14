import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_signs_screen.dart';

class AdminLessonsScreen extends StatelessWidget {
  final String levelId;
  final String stageId;

  const AdminLessonsScreen({
    super.key,
    required this.levelId,
    required this.stageId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text('إدارة الدروس')),
        floatingActionButton: FloatingActionButton(
          child: const Icon(Icons.add),
          onPressed: () async {
            await FirebaseFirestore.instance
                .collection('levels')
                .doc(levelId)
                .collection('stages')
                .doc(stageId)
                .collection('lessons')
                .add({
              'title': 'درس جديد',
              'order': 0,
              'animationUrl': '',
            });
          },
        ),
        body: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('levels')
                .doc(levelId)
                .collection('stages')
                .doc(stageId)
                .collection('lessons').orderBy('order')
                .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            return ListView(
              children: snapshot.data!.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return ListTile(
                  title: Text(data['title']),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AdminSignsScreen(
                          levelId: levelId,
                          stageId: stageId,
                          lessonId: doc.id,
                        ),
                      ),
                    );
                  },
                );
              }).toList(),
            );
          },
        ),
    );
  }
}
