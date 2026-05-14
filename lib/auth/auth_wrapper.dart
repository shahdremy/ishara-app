import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ishara/admin/admin_dashboard.dart';

import '../screens/splash_screen.dart';
import '../screens/register_screen.dart';
import '../screens/main_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  Future<bool> _isAdmin(User user) async {
    final token = await user.getIdTokenResult(true);
    return token.claims?['admin'] == true;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }

        // ❌ مش مسجل
        if (!snapshot.hasData) {
          return const RegisterScreen();
        }

        final user = snapshot.data!;

        return FutureBuilder<bool>(
          future: _isAdmin(user),
          builder: (context, adminSnap) {
            if (!adminSnap.hasData) {
              return const SplashScreen();
            }

            if (adminSnap.data == true) {
              return const AdminDashboard();
            }

            return const MainScreen();
          },
        );
      },
    );
  }
}
