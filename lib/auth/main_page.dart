import 'package:flutter/material.dart';
import 'package:towbruh/auth/auth_page.dart';
import 'package:towbruh/nav_bar_scaffold.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MainPage extends StatelessWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return FutureBuilder<String>(
            future: _getUserRole(snapshot.data!),
            builder: (context, roleSnapshot) {
              if (roleSnapshot.connectionState == ConnectionState.waiting) {
                return Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              return NavBarScaffold(userRole: roleSnapshot.data!);
            },
          );
        } else {
          return AuthPage();
        }
      },
    );
  }

  Future<String> _getUserRole(User user) async {
    // Fetch user role from Firestore
    // For example:
    // QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    // return snapshot.data()['role'];
    return 'customer'; // Replace with actual logic to fetch user role
  }
}
