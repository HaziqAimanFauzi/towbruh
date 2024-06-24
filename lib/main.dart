import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:towbruh/pages/home_page.dart';
import 'package:towbruh/pages/login.dart';
import 'package:towbruh/pages/register.dart';
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
        '/home': (context) => HomePage(userRole: 'customer'), // Replace 'customer' with the dynamic user role
        '/login': (context) => LoginPage(showRegisterPage: () {
          Navigator.pushNamed(context, '/register');
        }),
        '/register': (context) => RegisterPage(showLoginPage: () {
          Navigator.pushNamed(context, '/login');
        }),
      },
    );
  }
}
