import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class CustomerProfilePage extends StatefulWidget {
  @override
  _CustomerProfilePageState createState() => _CustomerProfilePageState();
}

class _CustomerProfilePageState extends State<CustomerProfilePage> {
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
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(_currentUser.uid).get();
    setState(() {
      _userData = userDoc.data() as Map<String, dynamic>?;
      _profileImageUrl = _userData!['profile_image'];
    });
  }

  Future<void> _uploadProfileImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      File file = File(pickedFile.path);
      String fileName = '${_currentUser.uid}.png';

      try {
        await FirebaseStorage.instance.ref('profile_images/$fileName').putFile(file);
        String downloadURL = await FirebaseStorage.instance.ref('profile_images/$fileName').getDownloadURL();

        await FirebaseFirestore.instance.collection('users').doc(_currentUser.uid).update({
          'profile_image': downloadURL,
        });

        setState(() {
          _profileImageUrl = downloadURL;
        });
      } catch (e) {
        print('Error uploading profile image: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Customer Profile'),
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
            Center(
              child: GestureDetector(
                onTap: _uploadProfileImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: _profileImageUrl != null
                      ? NetworkImage(_profileImageUrl!)
                      : AssetImage('assets/default_profile.png') as ImageProvider,
                ),
              ),
            ),
            SizedBox(height: 16),
            Text('Name: ${_userData!['name']}', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text('Email: ${_userData!['email']}', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text('Phone: ${_userData!['phone']}', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
