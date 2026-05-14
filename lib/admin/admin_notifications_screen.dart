import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminNotificationsScreen extends StatelessWidget {
  const AdminNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الإشعارات')),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          await FirebaseFirestore.instance.collection('notifications').add({
            'title': 'إشعار جديد',
            'createdAt': Timestamp.now(),
          });
        },
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
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