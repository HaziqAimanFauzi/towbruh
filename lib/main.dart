import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:towbruh/pages/home_page.dart';
import 'package:towbruh/pages/login.dart';
import 'package:towbruh/pages/register.dart';
import 'package:towbruh/pages/settings_page.dart';
import 'package:towbruh/pages/update_profile.dart'; // Import the update profile page
import 'nav_bar_scaffold.dart';
import 'auth/auth_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TowBruh',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => AuthPage(),
        '/home': (context) => NavBarScaffold(userRole: 'customer'), // Ensure userRole is passed correctly
        '/login': (context) => LoginPage(showRegisterPage: () {
          Navigator.pushNamed(context, '/register');
        }),
        '/register': (context) => RegisterPage(showLoginPage: () {
          Navigator.pushNamed(context, '/login');
        }),
        '/settings': (context) => const SettingsPage(),
        '/update_profile': (context) => UpdateProfilePage(), // Register the update profile route
      },
    );
  }
}
