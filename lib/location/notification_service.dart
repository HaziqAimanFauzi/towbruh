import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  void init() {
    _firebaseMessaging.requestPermission();
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // Handle foreground messages
      print('Received message: ${message.notification?.body}');
    });
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      // Handle messages that opened the app
      print('Message clicked!');
    });
  }

  Future<void> sendNotification(String token, String title, String body) async {
    // Send notification using FCM
  }
}
