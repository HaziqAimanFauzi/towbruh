import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class UpdateProfilePage extends StatefulWidget {
  @override
  _UpdateProfilePageState createState() => _UpdateProfilePageState();
}

class _UpdateProfilePageState extends State<UpdateProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late User _currentUser;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _numberPlateController = TextEditingController();
  String? _profileImageUrl;
  File? _profileImage;

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser!;
    _getUserData();
  }

  Future<void> _getUserData() async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(_currentUser.uid).get();
    final userData = userDoc.data() as Map<String, dynamic>;
    _nameController.text = userData['name'];
    _phoneController.text = userData['phone'];
    _numberPlateController.text = userData['number_plate'];
    setState(() {
      _profileImageUrl = userData['profile_image'];
    });
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      await FirebaseFirestore.instance.collection('users').doc(_currentUser.uid).update({
        'name': _nameController.text,
        'phone': _phoneController.text,
        'number_plate': _numberPlateController.text,
      });

      if (_profileImage != null) {
        String fileName = '${_currentUser.uid}.png';
        await FirebaseStorage.instance.ref('profile_images/$fileName').putFile(_profileImage!);
        String downloadURL = await FirebaseStorage.instance.ref('profile_images/$fileName').getDownloadURL();

        await FirebaseFirestore.instance.collection('users').doc(_currentUser.uid).update({
          'profile_image': downloadURL,
        });

        setState(() {
          _profileImageUrl = downloadURL;
        });
      }

      Navigator.pop(context);
    }
  }

  Future<void> _pickProfileImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Update Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_profileImageUrl != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: CircleAvatar(
                    radius: 80,
                    backgroundImage: NetworkImage(_profileImageUrl!),
                  ),
                ),
              ElevatedButton(
                onPressed: () => _pickProfileImage(ImageSource.camera),
                child: Text('Take Photo'),
              ),
              ElevatedButton(
                onPressed: () => _pickProfileImage(ImageSource.gallery),
                child: Text('Choose from Gallery'),
              ),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(labelText: 'Phone'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your phone number';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _numberPlateController,
                decoration: InputDecoration(labelText: 'Number Plate'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your vehicle number plate';
                  }
                  return null;
                },
              ),
              ElevatedButton(
                onPressed: _updateProfile,
                child: Text('Update Profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}