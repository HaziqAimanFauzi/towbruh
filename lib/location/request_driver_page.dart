import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:towbruh/pages/driver_home.dart';

class RequestDriverPage extends StatefulWidget {
  const RequestDriverPage({Key? key}) : super(key: key);

  @override
  _RequestDriverPageState createState() => _RequestDriverPageState();
}

class _RequestDriverPageState extends State<RequestDriverPage> {
  LatLng _currentPosition = const LatLng(45.521563, -122.677433);
  bool _isRequesting = false;
  String? _selectedService;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    setState(() {
      _currentPosition = LatLng(position.latitude, position.longitude);
    });
  }

  Future<void> _requestDriver() async {
    if (_selectedService == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a service type')),
      );
      return;
    }

    setState(() {
      _isRequesting = true;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final requestId = FirebaseFirestore.instance.collection('requests').doc().id;
      await FirebaseFirestore.instance.collection('requests').doc(requestId).set({
        'customerId': user.uid,
        'location': GeoPoint(_currentPosition.latitude, _currentPosition.longitude),
        'serviceType': _selectedService,
        'status': 'requested',
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Driver requested successfully')),
      );

      // Navigate to DriverHomePage
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const DriverHomePage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User not logged in')),
      );
    }

    setState(() {
      _isRequesting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Request Driver'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Location:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black),
              ),
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _currentPosition,
                  zoom: 15.0,
                ),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Select Service:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            DropdownButton<String>(
              value: _selectedService,
              hint: Text('Choose a service'),
              items: <String>['Towing', 'Jump Start', 'Tire Change', 'Fuel Delivery']
                  .map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedService = newValue;
                });
              },
            ),
            SizedBox(height: 20),
            Center(
              child: _isRequesting
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                onPressed: _requestDriver,
                child: Text('Request Driver'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
