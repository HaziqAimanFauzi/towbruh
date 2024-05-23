import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../nav_bar_scaffold.dart';
import 'customer_profile.dart';
import 'tow_profile.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late String _userRole = '';
  int _selectedIndex = 0;
  List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
    _fetchUserRole();
  }

  Future<void> _fetchUserRole() async {
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      setState(() {
        _userRole = userDoc['role'];
        _pages = [
          Center(child: Text('Welcome! You are logged in as $_userRole.')),
          _userRole == 'customer' ? CustomerProfilePage() : TowDriverProfilePage(),
          // SettingsPage(),
        ];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return NavBarScaffold(
      initialIndex: _selectedIndex,
      pages: _pages.isEmpty ? [Center(child: CircularProgressIndicator())] : _pages,
    );
  }
}
