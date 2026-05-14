import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_lessons_screen.dart';

class AdminStagesScreen extends StatelessWidget {
  final String levelId;
  const AdminStagesScreen({super.key, required this.levelId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إدارة المراحل')),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          await FirebaseFirestore.instance
              .collection('levels')
              .doc(levelId)
              .collection('stages')
              .add({
            'title': 'مرحلة جديدة',
            'order': 0,
          });
        },
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('levels')
            .doc(levelId)
            .collection('stages')
            .orderBy('order')
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
                      builder: (_) => AdminLessonsScreen(
                        levelId: levelId,
                        stageId: doc.id,
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