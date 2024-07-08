import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class RequestDriverPage extends StatefulWidget {
  @override
  _RequestDriverPageState createState() => _RequestDriverPageState();
}

class _RequestDriverPageState extends State<RequestDriverPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Set<Marker> _markers = {};
  GoogleMapController? _mapController;

  void _drawRoute(LatLng customerLatLng) {
    // Implement route drawing logic here
  }

  Future<void> _acceptRequest(String requestId) async {
    final currentUser = _auth.currentUser;
    await _firestore.collection('requests').doc(requestId).update({
      'status': 'accepted',
      'driver_id': currentUser!.uid,
    });

    DocumentSnapshot requestDoc = await _firestore.collection('requests').doc(requestId).get();
    GeoPoint customerLocation = requestDoc['location'];
    LatLng customerLatLng = LatLng(customerLocation.latitude, customerLocation.longitude);
    String customerId = requestDoc['customer_id'];

    // Create chat room
    String chatRoomId = _firestore.collection('chatRooms').doc().id;
    await _firestore.collection('chatRooms').doc(chatRoomId).set({
      'participants': [currentUser.uid, customerId],
    });

    setState(() {
      _markers.add(
        Marker(
          markerId: MarkerId('customerMarker'),
          position: customerLatLng,
          infoWindow: const InfoWindow(title: 'Customer'),
        ),
      );
    });

    _drawRoute(customerLatLng);

    Navigator.pushNamed(context, '/messages');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Request Driver'),
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (controller) {
              _mapController = controller;
            },
            markers: _markers,
            initialCameraPosition: CameraPosition(
              target: LatLng(37.7749, -122.4194),
              zoom: 10,
            ),
          ),
          Positioned(
            bottom: 50,
            left: 10,
            right: 10,
            child: ElevatedButton(
              onPressed: () => _acceptRequest('request_id_placeholder'), // Replace with actual request ID
              child: Text('Accept Request'),
            ),
          ),
        ],
      ),
    );
  }
}
