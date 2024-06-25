import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RequestDriverPage extends StatefulWidget {
  @override
  _RequestDriverPageState createState() => _RequestDriverPageState();
}

class _RequestDriverPageState extends State<RequestDriverPage> {
  final _currentUser = FirebaseAuth.instance.currentUser!;
  late CollectionReference _requests;

  @override
  void initState() {
    super.initState();
    _requests = FirebaseFirestore.instance.collection('requests');
  }

  void _requestDriver() async {
    await _requests.add({
      'customer_id': _currentUser.uid,
      'status': 'pending',
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Request Driver')),
      body: Center(
        child: ElevatedButton(
          onPressed: _requestDriver,
          child: Text('Request Driver'),
        ),
      ),
    );
  }
}
