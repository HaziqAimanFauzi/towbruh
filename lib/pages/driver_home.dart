import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:towbruh/message/message_page.dart';
import 'package:towbruh/pages/profile_page.dart';
import 'package:towbruh/location/request_list.dart'; // Import the RequestListPage

class DriverHomePage extends StatefulWidget {
  const DriverHomePage({Key? key}) : super(key: key);

  @override
  _DriverHomePageState createState() => _DriverHomePageState();
}

class _DriverHomePageState extends State<DriverHomePage> {
  int _selectedIndex = 0;
  late GoogleMapController _mapController;
  LatLng _initialPosition = const LatLng(45.521563, -122.677433);
  LatLng _currentPosition = const LatLng(45.521563, -122.677433);
  bool _locationPermissionGranted = false;
  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};
  late PolylinePoints _polylinePoints;
  final String googleApiKey = 'YOUR_API_KEY';
  late Stream<QuerySnapshot> _chats; // Stream for chat rooms

  final List<Widget> _widgetOptionsDriver = [
    const Text('Home Page Content'),
    MessagePage(),
    ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    _polylinePoints = PolylinePoints();
    _checkLocationPermission();
    _loadChatRooms(); // Initialize chat room stream
    _setupGeofenceService(); // Setup geofence service
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

  Future<void> _getCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    setState(() {
      _currentPosition = LatLng(position.latitude, position.longitude);
      _initialPosition = _currentPosition;
      _addDriverMarker();
    });
  }

  void _addDriverMarker() {
    setState(() {
      _markers.add(
        Marker(
          markerId: const MarkerId('driverMarker'),
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

  void _loadChatRooms() {
    _chats = FirebaseFirestore.instance
        .collection('chatRooms')
        .where('participants', arrayContains: FirebaseAuth.instance.currentUser!.uid)
        .snapshots();
  }

  void _navigateToRequestList() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => RequestListPage()),
    );
  }

  // Method to setup geofence service
  void _setupGeofenceService() {
    // Initialize and configure your GeofenceService here
    // You can use the provided code from before
    // Ensure you initialize and start the geofence service appropriately
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orange[500],
        title: Text('Driver Home'),
        automaticallyImplyLeading: false, // Remove back button
      ),
      body: Center(
        child: _selectedIndex == 0
            ? _locationPermissionGranted
            ? GoogleMap(
          onMapCreated: _onMapCreated,
          initialCameraPosition: CameraPosition(
            target: _initialPosition,
            zoom: 15.0,
          ),
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          markers: _markers,
          polylines: _polylines,
        )
            : const Text('Location permission not granted')
            : _widgetOptionsDriver.elementAt(_selectedIndex),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToRequestList,
        tooltip: 'View Requests',
        child: Icon(
            Icons.list,
            color: Colors.white,
          ),
        backgroundColor: Colors.blue, // Set the background color to blue
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat, // Aligns FAB to the start (left)
    );
  }
}
