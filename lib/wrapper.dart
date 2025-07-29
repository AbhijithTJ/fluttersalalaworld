import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:wetherapp/home_page.dart';
import 'package:wetherapp/login_page.dart';
import 'package:wetherapp/services/auth_service.dart';


class Wrapper extends StatelessWidget {
  const Wrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    return StreamBuilder<User?>(
      stream: authService.user,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        if (snapshot.hasData) {
          final User? user = snapshot.data;
          if (user != null) {
            return FutureBuilder<Map<String, dynamic>?>(
              future: authService.getUserRoleAndName(user.uid),
              builder: (context, roleAndNameSnapshot) {
                if (roleAndNameSnapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                if (roleAndNameSnapshot.hasData && roleAndNameSnapshot.data != null) {
                  final String? userName = roleAndNameSnapshot.data!['userName'];
                  final String? role = roleAndNameSnapshot.data!['role'];
                  return HomePage(userName: userName ?? user.displayName ?? user.email ?? 'User', role: role ?? 'user');
                }
                // Fallback if role and name data is not available
                return HomePage(userName: user.displayName ?? user.email ?? 'User', role: 'user');
              },
            );
          }
          return const LoginPage(); // Should not happen if snapshot.hasData is true
        } else {
          return const LoginPage();
        }
      },
    );
  }
}
