import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ishara/screens/learning_screen.dart';
import 'admin_dashboard.dart';

class RoleGate extends StatelessWidget {
  const RoleGate({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: FirebaseAuth.instance.currentUser!.getIdTokenResult(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final claims = snapshot.data!.claims ?? {};
        final isAdmin = claims['admin'] == true;

        return isAdmin ? const AdminDashboard() : LearningScreen();
      },
    );
  }
}