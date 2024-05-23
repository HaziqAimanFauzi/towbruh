import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TowDriverProfilePage extends StatefulWidget {
  @override
  _TowDriverProfilePageState createState() => _TowDriverProfilePageState();
}

class _TowDriverProfilePageState extends State<TowDriverProfilePage> {
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      setState(() {
        _userData = userDoc.data() as Map<String, dynamic>;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tow Driver Profile'),
      ),
      body: _userData == null
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: ${_userData!['name']}'),
            Text('Email: ${_userData!['email']}'),
            Text('Phone Number: ${_userData!['phone']}'),
            Text('Tow Truck Number Plate: ${_userData!['tow_truck_number_plate']}'),
            SizedBox(height: 20),
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundImage: NetworkImage(_userData!['profile_picture'] ?? ''),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
