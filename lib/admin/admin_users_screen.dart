import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminUsersScreen extends StatelessWidget {
  const AdminUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text('إدارة المستخدمين')),
        body: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data!.docs;

              return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final data = docs[i].data() as Map<String, dynamic>;
                    return ListTile(
                        title: Text(data['name'] ?? 'بدون اسم'),
                        subtitle: Text(data['email'] ?? ''),
                        trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(docs[i].id)
                                .delete();
                          },
                        ),
                    );
                  },
              );
            },
        ),
    );
  }
}