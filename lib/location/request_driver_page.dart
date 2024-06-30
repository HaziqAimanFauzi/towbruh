import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class RequestDriverPage extends StatefulWidget {
  @override
  _RequestDriverPageState createState() => _RequestDriverPageState();
}

class _RequestDriverPageState extends State<RequestDriverPage> {
  final _currentUser = FirebaseAuth.instance.currentUser!;
  late CollectionReference _requests;
  late CollectionReference _users;
  String _requestId = '';
  bool _isRequestPending = false;
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _requests = FirebaseFirestore.instance.collection('requests');
    _users = FirebaseFirestore.instance.collection('users');
    _fetchUserRole();
  }

  Future<void> _fetchUserRole() async {
    final userDoc = await _users.doc(_currentUser.uid).get();
    setState(() {
      _userRole = userDoc['role'];
    });
  }

  void _requestDriver() async {
    final requestRef = await _requests.add({
      'customer_id': _currentUser.uid,
      'status': 'pending',
      'created_at': FieldValue.serverTimestamp(),
    });

    setState(() {
      _requestId = requestRef.id;
      _isRequestPending = true;
    });

    _startRequestTimer(requestRef.id);
  }

  void _startRequestTimer(String requestId) {
    Timer(Duration(seconds: 30), () async {
      final request = await _requests.doc(requestId).get();
      if (request.exists && request['status'] == 'pending') {
        await _requests.doc(requestId).update({'status': 'canceled'});
        setState(() {
          _isRequestPending = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Request timed out and was canceled.')),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_userRole == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Request Driver')),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Request Driver')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isRequestPending)
              Text('Request is pending...'),
            SizedBox(height: 20),
            if (_userRole == 'customer')
              ElevatedButton(
                onPressed: _isRequestPending ? null : _requestDriver,
                child: Text('Request Driver'),
              ),
          ],
        ),
      ),
    );
  }
}
