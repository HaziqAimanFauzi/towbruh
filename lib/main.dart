import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:towbruh/location/request_driver_page.dart';
import 'package:towbruh/message/message_page.dart';
import 'package:towbruh/pages/login.dart';
import 'package:towbruh/pages/register.dart';
import 'package:towbruh/pages/settings_page.dart';
import 'package:towbruh/pages/update_profile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'nav_bar_scaffold.dart';
import 'auth/auth_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  runApp(MyApp());
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Handling a background message: ${message.messageId}');
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;
      if (notification != null && android != null) {
        showDialog(
          context: context,
          builder: (_) {
            return AlertDialog(
              title: Text(notification.title ?? 'Notification'),
              content: SingleChildScrollView(
                child: Column(
                  children: [Text(notification.body ?? 'No body')],
                ),
              ),
            );
          },
        );
      }
    });

    return MaterialApp(
      title: 'TowBruh',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => AuthPage(),
        '/cust_home': (context) => NavBarScaffold(userRole: 'customer'),
        '/driver_home': (context) => NavBarScaffold(userRole: 'tow'),
        '/login': (context) => LoginPage(showRegisterPage: () {
          Navigator.pushNamed(context, '/register');
        }),
        '/register': (context) => RegisterPage(showLoginPage: () {
          Navigator.pushNamed(context, '/login');
        }),
        '/settings': (context) => const SettingsPage(),
        '/update_profile': (context) => UpdateProfilePage(),
        '/request_driver': (context) => RequestDriverPage(),
        '/messages': (context) => MessagePage(),
      },
    );
  }
}


class UserService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> saveToken() async {
    String? token = await _messaging.getToken();
    if (token != null) {
      User? user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'fcm_token': token,
        });
      }
    }
  }
}
