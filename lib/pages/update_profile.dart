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
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  String? _profileImageUrl;
  File? _profileImage;
  String? _role;
  bool _isLoading = false; // Add isLoading state variable

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
      setState(() {
        _isLoading = true; // Set loading state to true when updating profile
      });

      try {
        // Update email if changed
        if (_emailController.text != _currentUser.email) {
          AuthCredential credential = EmailAuthProvider.credential(
            email: _currentUser.email!,
            password: _currentPasswordController.text,
          );
          await _currentUser.reauthenticateWithCredential(credential);

          await _currentUser.updateEmail(_emailController.text);
          await FirebaseAuth.instance.currentUser!.sendEmailVerification();
        }

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
          Reference storageRef = FirebaseStorage.instance.ref().child('profile_images/$fileName');
          UploadTask uploadTask = storageRef.putFile(_profileImage!);

          uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
            print('Progress: ${(snapshot.bytesTransferred / snapshot.totalBytes) * 100} %');
          }, onError: (e) {
            print(uploadTask.snapshot);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error uploading profile image: $e')),
            );
          });

          await uploadTask.whenComplete(() async {
            try {
              String downloadURL = await storageRef.getDownloadURL();

              await FirebaseFirestore.instance.collection('users').doc(_currentUser.uid).update({
                'profile_image': downloadURL,
              });

              setState(() {
                _profileImageUrl = downloadURL;
              });
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error getting download URL: $e')),
              );
            }
          });
        }

        setState(() {
          _isLoading = false; // Set loading state to false after update completes
        });

        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile updated successfully. Please verify your new email.')),
        );
      } catch (e) {
        setState(() {
          _isLoading = false; // Set loading state to false if there's an error
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
        );
      }
    }
  }

  Future<void> _changePassword() async {
    if (_newPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter new password')),
      );
      return;
    }

    try {
      AuthCredential credential = EmailAuthProvider.credential(
        email: _currentUser.email!,
        password: _currentPasswordController.text,
      );
      await _currentUser.reauthenticateWithCredential(credential);

      await _currentUser.updatePassword(_newPasswordController.text);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password changed successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to change password. ${e.toString()}')),
      );
    }
  }

  Future<void> _pickProfileImage() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.camera_alt),
            title: Text('Take Photo'),
            onTap: () async {
              Navigator.pop(context);
              final pickedFile = await ImagePicker().pickImage(source: ImageSource.camera);
              if (pickedFile != null) {
                setState(() {
                  _profileImage = File(pickedFile.path);
                });
              }
            },
          ),
          ListTile(
            leading: Icon(Icons.photo_library),
            title: Text('Choose from Gallery'),
            onTap: () async {
              Navigator.pop(context);
              final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
              if (pickedFile != null) {
                setState(() {
                  _profileImage = File(pickedFile.path);
                });
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProfileImage() {
    return Stack(
      children: [
        CircleAvatar(
          radius: 80,
          backgroundImage: _profileImage != null
              ? FileImage(_profileImage!)
              : _profileImageUrl != null
              ? NetworkImage(_profileImageUrl!) as ImageProvider<Object>
              : AssetImage('assets/default_profile.png') as ImageProvider<Object>,
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: _pickProfileImage,
            child: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.camera_alt, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orange[700],
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
                Center(
                  child: _buildProfileImage(),
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: 'Phone',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your phone number';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                if (_role == 'tow')
                  TextFormField(
                    controller: _numberPlateController,
                    decoration: InputDecoration(
                      labelText: 'Number Plate',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your vehicle number plate';
                      }
                      return null;
                    },
                  ),
                if (_role == 'tow') SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _currentPasswordController,
                  decoration: InputDecoration(
                    labelText: 'Current Password (Required to change password)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (_newPasswordController.text.isNotEmpty && (value == null || value.isEmpty)) {
                      return 'Please enter your current password';
                    }
                    return null;
                  },
                  obscureText: true,
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _newPasswordController,
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (_currentPasswordController.text.isNotEmpty && (value == null || value.isEmpty)) {
                      return 'Please enter your new password';
                    }
                    return null;
                  },
                  obscureText: true,
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    _updateProfile();
                    if (_newPasswordController.text.isNotEmpty) {
                      _changePassword();
                    }
                  },
                  child: _isLoading
                      ? CircularProgressIndicator() // Show loading indicator if updating
                      : Text('Update Profile'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
