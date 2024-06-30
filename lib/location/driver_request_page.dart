import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class DriverRequestsPage extends StatefulWidget {
  @override
  _DriverRequestsPageState createState() => _DriverRequestsPageState();
}

class _DriverRequestsPageState extends State<DriverRequestsPage> {
  final _currentUser = FirebaseAuth.instance.currentUser!;
  final CollectionReference _requests = FirebaseFirestore.instance.collection('requests');
  final CollectionReference _locations = FirebaseFirestore.instance.collection('locations');
  LatLng? _customerLocation;
  String? _acceptedRequestId;

  void _acceptRequest(String requestId, String customerId) async {
    await _requests.doc(requestId).update({
      'status': 'accepted',
      'driver_id': _currentUser.uid,
    });

    // Fetch customer location
    final customerLocationSnapshot = await _locations.doc(customerId).get();
    if (customerLocationSnapshot.exists) {
      setState(() {
        _customerLocation = LatLng(
          customerLocationSnapshot['latitude'],
          customerLocationSnapshot['longitude'],
        );
        _acceptedRequestId = requestId;
      });
    }
  }

  void _startLocationUpdates() {
    Geolocator.getPositionStream(locationSettings: LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10)).listen((Position position) {
      _locations.doc(_currentUser.uid).set({
        'latitude': position.latitude,
        'longitude': position.longitude,
        'timestamp': FieldValue.serverTimestamp(),
      });
    });
  }

  @override
  void initState() {
    super.initState();
    _startLocationUpdates();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Driver Requests')),
      body: _acceptedRequestId == null
          ? StreamBuilder<QuerySnapshot>(
        stream: _requests.where('status', isEqualTo: 'pending').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }
          final requests = snapshot.data!.docs;
          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              return ListTile(
                title: Text('Request from customer: ${request['customer_id']}'),
                trailing: ElevatedButton(
                  onPressed: () => _acceptRequest(request.id, request['customer_id']),
                  child: Text('Accept'),
                ),
              );
            },
          );
        },
      )
          : Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Guiding to customer...'),
            if (_customerLocation != null)
              SizedBox(
                height: 300,
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _customerLocation!,
                    zoom: 14,
                  ),
                  markers: {
                    Marker(
                      markerId: MarkerId('customer'),
                      position: _customerLocation!,
                    ),
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
