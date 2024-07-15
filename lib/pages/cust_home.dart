import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:towbruh/message/chat_page.dart';
import 'package:towbruh/message/message_page.dart';
import 'package:towbruh/pages/profile_page.dart';

class CustomerHomePage extends StatefulWidget {
  const CustomerHomePage({Key? key}) : super(key: key);

  @override
  _CustomerHomePageState createState() => _CustomerHomePageState();
}

class _CustomerHomePageState extends State<CustomerHomePage> {
  int _selectedIndex = 0;
  late GoogleMapController _mapController;
  LatLng _initialPosition = const LatLng(45.521563, -122.677433);
  LatLng _currentPosition = const LatLng(45.521563, -122.677433);
  bool _locationPermissionGranted = false;
  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};
  late PolylinePoints _polylinePoints;
  final String googleApiKey = 'YOUR_API_KEY';
  String? _driverId;
  StreamSubscription<DocumentSnapshot>? _driverLocationSubscription;
  String? _userRole;
  Map<String, dynamic>? _driverData; // Added to store driver data

  final List<Widget> _widgetOptionsCustomer = [
    const Text('Home Page Content'),
    MessagePage(),
    ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    _polylinePoints = PolylinePoints();
    _checkLocationPermission();
    _fetchUserRole();
  }

  @override
  void dispose() {
    _driverLocationSubscription?.cancel();
    super.dispose();
  }

  Future<void> _checkLocationPermission() async {
    var status = await Permission.location.status;
    if (status.isDenied) {
      status = await Permission.location.request();
    }

    if (status.isGranted) {
      _locationPermissionGranted = true;
      _getCurrentLocation();
    } else {
      print("Location permission denied");
    }
  }

  Future<void> _fetchUserRole() async {
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid).get();
    setState(() {
      _userRole = userDoc['role'];
    });
  }

  Future<void> _getCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    setState(() {
      _currentPosition = LatLng(position.latitude, position.longitude);
      _initialPosition = _currentPosition;
      _addCustomerMarker();
    });
  }

  void _addCustomerMarker() {
    setState(() {
      _markers.add(
        Marker(
          markerId: const MarkerId('customerMarker'),
          position: _currentPosition,
          infoWindow: const InfoWindow(title: 'Your Location'),
        ),
      );
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _requestDriver() async {
    if (_userRole != 'customer') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Only customers can request a driver.')),
      );
      return;
    }

    DocumentReference requestRef = await FirebaseFirestore.instance.collection('requests').add(
      {
        'customer_id': FirebaseAuth.instance.currentUser!.uid,
        'location': GeoPoint(
          _currentPosition.latitude,
          _currentPosition.longitude,
        ),
        'status': 'pending',
      },
    );

    _showRequestSentDialog();
    _listenForDriverAcceptance(requestRef.id);
  }

  void _showRequestSentDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request Sent'),
        content: const Text('Waiting for a driver to accept your request.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _listenForDriverAcceptance(String requestId) {
    FirebaseFirestore.instance.collection('requests').doc(requestId).snapshots().listen((snapshot) {
      if (snapshot.exists && snapshot['status'] == 'accepted') {
        setState(() {
          _driverId = snapshot['driver_id'];
        });
        _fetchDriverData(snapshot['driver_id']); // Fetch driver data
        _startTrackingDriverLocation();

        // Create a chat room between the customer and the driver
        _createChatRoom(snapshot['driver_id']);
      }
    });
  }

  Future<void> _fetchDriverData(String driverId) async {
    DocumentSnapshot driverDoc = await FirebaseFirestore.instance.collection('users').doc(driverId).get();
    setState(() {
      _driverData = driverDoc.data() as Map<String, dynamic>?;
    });
  }

  Future<void> _createChatRoom(String driverId) async {
    final currentUser = FirebaseAuth.instance.currentUser!;
    DocumentReference chatRoomRef = await FirebaseFirestore.instance.collection('chatRooms').add({
      'participants': [currentUser.uid, driverId],
      'lastMessage': '',
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Fetch driver details
    DocumentSnapshot driverDoc = await FirebaseFirestore.instance.collection('users').doc(driverId).get();
    Map<String, dynamic> driverData = driverDoc.data() as Map<String, dynamic>;

    // Navigate to chat room
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatPage(
          chatRoomId: chatRoomRef.id,
          user: driverData,
          recipientId: driverId,
        ),
      ),
    );
  }

  void _startTrackingDriverLocation() {
    if (_driverId == null) return;

    _driverLocationSubscription = FirebaseFirestore.instance.collection('drivers').doc(_driverId).snapshots().listen((snapshot) {
      if (snapshot.exists) {
        GeoPoint driverLocation = snapshot['location'];
        LatLng driverLatLng = LatLng(driverLocation.latitude, driverLocation.longitude);

        setState(() {
          _markers.removeWhere((marker) => marker.markerId.value == 'driverMarker');
          _markers.add(
            Marker(
              markerId: const MarkerId('driverMarker'),
              position: driverLatLng,
              infoWindow: const InfoWindow(title: 'Driver Location'),
            ),
          );
        });
      }
    });
  }

  Widget _buildDriverAcceptedInfo() {
    if (_driverData == null) {
      return SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 3,
            blurRadius: 5,
            offset: Offset(0, 3), // changes position of shadow
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Driver Accepted Your Request', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('Name: ${_driverData!['name']}'),
          Text('Phone: ${_driverData!['phone']}'),
          Text('Number Plate: ${_driverData!['number_plate']}'),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // Removes the back button
        backgroundColor: Colors.orange[700],
        title: Text('Customer Home'),
      ),
      body: Center(
        child: _selectedIndex == 0
            ? _locationPermissionGranted
            ? Stack(
          children: [
            GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: _initialPosition,
                zoom: 15.0,
              ),
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              markers: _markers,
              polylines: _polylines,
            ),
            Positioned(
              bottom: 20,
              left: 20,
              child: Row(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      iconSize: 50,
                      icon: const Icon(Icons.search, color: Colors.white),
                      onPressed: _requestDriver,
                      tooltip: 'Request Driver',
                    ),
                  ),
                  const SizedBox(width: 100),
                ],
              ),
            ),
            if (_driverData != null) // Show driver accepted info if available
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: _buildDriverAcceptedInfo(),
              ),
          ],
        )
            : Center(child: CircularProgressIndicator())
            : _widgetOptionsCustomer[_selectedIndex],
      ),
    );
  }
}
