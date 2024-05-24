import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SettingsPage extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _changePassword(BuildContext context) async {
    // Implement password change functionality
    // You can prompt the user to enter their current and new passwords, then update it in Firebase Auth
  }

  Future<void> _updateProfile(BuildContext context) async {
    // Implement profile update functionality
    // This can include updating the user's display name, profile picture, etc.
  }

  Future<void> _signOut(BuildContext context) async {
    await _auth.signOut();
    Navigator.of(context).pushReplacementNamed('/login'); // Ensure you have a named route for login
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: Icon(Icons.lock),
              title: Text('Change Password'),
              onTap: () => _changePassword(context),
            ),
            ListTile(
              leading: Icon(Icons.edit),
              title: Text('Update Profile'),
              onTap: () => _updateProfile(context),
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Log Out'),
              onTap: () => _signOut(context),
            ),
          ],
        ),
      ),
    );
  }
}
