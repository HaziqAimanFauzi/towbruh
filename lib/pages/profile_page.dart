import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late User _currentUser;
  Map<String, dynamic>? _userData;
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser!;
    _getUserData();
  }

  Future<void> _getUserData() async {
    DocumentSnapshot userDoc =
    await FirebaseFirestore.instance.collection('users').doc(_currentUser.uid).get();
    setState(() {
      _userData = userDoc.data() as Map<String, dynamic>?;
      _profileImageUrl = _userData!['profile_image'];
    });
  }

  Widget _buildProfileImage() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 3,
            blurRadius: 5,
            offset: Offset(0, 3), // changes position of shadow
          ),
        ],
      ),
      child: ClipOval(
        child: _profileImageUrl != null
            ? Image.network(
          _profileImageUrl!,
          fit: BoxFit.cover,
        )
            : Image.asset(
          'assets/default_profile.png',
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildUserDataInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // Removes the back button
        backgroundColor: Colors.orange[500],
        title: Text('Profile'),
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
          : SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: _buildProfileImage(),
              ),
            ),
            Container(
              padding: EdgeInsets.all(26),
              decoration: BoxDecoration(
                color: Colors.white70,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 3,
                    blurRadius: 5,
                    offset: Offset(0, 3), // changes position of shadow
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildUserDataInfo('Name', _userData!['name']),
                  _buildUserDataInfo('Email', _userData!['email']),
                  _buildUserDataInfo('Phone', _userData!['phone']),
                  if (_userData!['role'] == 'tow') ...[
                    Divider(),
                    _buildUserDataInfo('Number Plate', _userData!['number_plate']),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
