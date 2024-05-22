import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../bottom_nav_bar.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late String _userRole;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchUserRole();
  }

  Future<void> _fetchUserRole() async {
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      setState(() {
        _userRole = userDoc['role'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return NavBarScaffold(
      initialIndex: _selectedIndex,
      pages: [
        Center(
          child: _userRole.isNotEmpty
              ? Text('Welcome! You are logged in as $_userRole.')
              : CircularProgressIndicator(),
        ),
        Center(
          child: Text('Profile Page'),
        ),
        Center(
          child: Text('Settings Page'),
        ),
      ],
    );
  }
}
