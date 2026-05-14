import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'admin_content_screen.dart';
import 'admin_notifications_screen.dart';
import 'admin_users_screen.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة تحكم المسؤول'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _card(context, 'إدارة المستخدمين', Icons.people,
              const AdminUsersScreen()),
          _card(context, 'إدارة المحتوى التعليمي', Icons.school,
              const AdminContentScreen()),
          _card(context, 'الإشعارات', Icons.notifications,
              const AdminNotificationsScreen()),
        ],
      ),
    );
  }

  Widget _card(
      BuildContext context, String title, IconData icon, Widget page) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          Navigator.push(
              context, MaterialPageRoute(builder: (_) => page));
        },
      ),
    );
  }
}
