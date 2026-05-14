import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminContentScreen extends StatelessWidget {
  const AdminContentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المحتوى التعليمي')),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          await FirebaseFirestore.instance.collection('levels').add({
            'title': 'مستوى جديد',
            'createdAt': Timestamp.now(),
          });
        },
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('levels').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView(
            children: snapshot.data!.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return ListTile(
                title: Text(data['title'] ?? 'بدون عنوان'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
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