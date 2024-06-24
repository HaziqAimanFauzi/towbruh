import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TowProfilePage extends StatefulWidget {
  @override
  _TowProfilePageState createState() => _TowProfilePageState();
}

class _TowProfilePageState extends State<TowProfilePage> {
  late User _currentUser;
  late Map<String, dynamic> _userData;

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser!;
    _getUserData();
  }

  Future<void> _getUserData() async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(_currentUser.uid).get();
    setState(() {
      _userData = userDoc.data() as Map<String, dynamic>;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tow Profile'),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
        ],
      ),
      body: _userData == null
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: ${_userData['name']}', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text('Email: ${_userData['email']}', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text('Phone: ${_userData['phone']}', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text('Number Plate: ${_userData['number_plate']}', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            // Profile picture can be added here
          ],
        ),
      ),
    );
  }
}
