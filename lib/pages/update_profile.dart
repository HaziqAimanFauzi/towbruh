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
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController(); // Add password controller for re-authentication
  String? _profileImageUrl;
  File? _profileImage;
  String? _role;

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
    _numberPlateController.text = userData['number_plate'] ?? '';
    _emailController.text = userData['email']; // Set initial email
    _role = userData['role'];
    setState(() {
      _profileImageUrl = userData['profile_image'];
    });
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Reauthenticate user
        AuthCredential credential = EmailAuthProvider.credential(
          email: _currentUser.email!,
          password: _passwordController.text,
        );
        await _currentUser.reauthenticateWithCredential(credential);

        // Update email
        await _currentUser.updateEmail(_emailController.text);
        await FirebaseAuth.instance.currentUser!.sendEmailVerification();

        // Update Firestore document
        Map<String, dynamic> updateData = {
          'name': _nameController.text,
          'phone': _phoneController.text,
          'email': _emailController.text,
        };

        if (_role == 'tow') {
          updateData['number_plate'] = _numberPlateController.text;
        }

        await FirebaseFirestore.instance.collection('users').doc(_currentUser.uid).update(updateData);

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile updated successfully. Please verify your new email.')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
        );
      }
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
          child: SingleChildScrollView(
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
                if (_role == 'tow')
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
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(labelText: 'Email'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password for re-authentication';
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
      ),
    );
  }
}
