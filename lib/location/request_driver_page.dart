import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';

class RequestDriverPage extends StatefulWidget {
  @override
  _RequestDriverPageState createState() => _RequestDriverPageState();
}

class _RequestDriverPageState extends State<RequestDriverPage> {
  final _currentUser = FirebaseAuth.instance.currentUser!;
  late CollectionReference _requests;
  late CollectionReference _users;
  late CollectionReference _locations;
  String _requestId = '';
  bool _isRequestPending = false;
  String? _userRole;
  LatLng? _driverLocation;
  StreamSubscription<DocumentSnapshot>? _driverLocationSubscription;

  @override
  void initState() {
    super.initState();
    _requests = FirebaseFirestore.instance.collection('requests');
    _users = FirebaseFirestore.instance.collection('users');
    _locations = FirebaseFirestore.instance.collection('locations');
    _fetchUserRole();
  }

  Future<void> _fetchUserRole() async {
    final userDoc = await _users.doc(_currentUser.uid).get();
    setState(() {
      _userRole = userDoc['role'];
    });
  }

  void _requestDriver() async {
    if (_userRole != 'customer') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Only customers can request a driver.')),
      );
      return;
    }

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
    _listenForDriverAcceptance(requestRef.id);
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

  void _listenForDriverAcceptance(String requestId) {
    _requests.doc(requestId).snapshots().listen((requestSnapshot) async {
      if (requestSnapshot.exists && requestSnapshot['status'] == 'accepted') {
        final driverId = requestSnapshot['driver_id'];
        _driverLocationSubscription = _locations.doc(driverId).snapshots().listen((locationSnapshot) {
          if (locationSnapshot.exists) {
            setState(() {
              _driverLocation = LatLng(
                locationSnapshot['latitude'],
                locationSnapshot['longitude'],
              );
            });
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _driverLocationSubscription?.cancel();
    super.dispose();
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
              Column(
                children: [
                  Text('Request is pending...'),
                  if (_driverLocation != null)
                    SizedBox(
                      height: 300,
                      child: GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: _driverLocation!,
                          zoom: 14,
                        ),
                        markers: {
                          Marker(
                            markerId: MarkerId('driver'),
                            position: _driverLocation!,
                          ),
                        },
                      ),
                    ),
                ],
              ),
            SizedBox(height: 20),
            if (_userRole == 'customer')
              ElevatedButton(
                onPressed: _isRequestPending ? null : _requestDriver,
                child: Text('Request Driver'),
              ),
            if (_userRole != 'customer')
              Text('Only customers can request a driver.'),
          ],
        ),
      ),
    );
  }
}
