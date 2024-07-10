import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:towbruh/message/message_page.dart';
import 'package:towbruh/pages/profile_page.dart';

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
  StreamSubscription<QuerySnapshot>? _requestSubscription;

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
    _listenForRequests();
  }

  @override
  void dispose() {
    _requestSubscription?.cancel();
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

  void _listenForRequests() {
    // Listen for requests here, or implement a different logic for driver's page
  }

  void _acceptRequest(String requestId, Map<String, dynamic> requestData) async {
    await FirebaseFirestore.instance.collection('requests').doc(requestId).update({
      'status': 'accepted',
      'driver_id': FirebaseAuth.instance.currentUser!.uid,
    });

    _navigateToCustomer(requestData);
  }

  void _navigateToCustomer(Map<String, dynamic> requestData) {
    GeoPoint customerLocation = requestData['location'];
    LatLng customerLatLng = LatLng(customerLocation.latitude, customerLocation.longitude);

    setState(() {
      _markers.add(
        Marker(
          markerId: const MarkerId('customerMarker'),
          position: customerLatLng,
          infoWindow: const InfoWindow(title: 'Customer Location'),
        ),
      );

      _mapController.animateCamera(
        CameraUpdate.newLatLng(customerLatLng),
      );
    });

    // Start tracking driver's location to update in Firestore
    _startTrackingDriverLocation();
  }

  void _startTrackingDriverLocation() {
    Geolocator.getPositionStream().listen((Position position) {
      FirebaseFirestore.instance.collection('drivers').doc(FirebaseAuth.instance.currentUser!.uid).update({
        'location': GeoPoint(position.latitude, position.longitude),
      });

      LatLng driverLatLng = LatLng(position.latitude, position.longitude);

      setState(() {
        _markers.removeWhere((marker) => marker.markerId.value == 'driverMarker');
        _markers.add(
          Marker(
            markerId: const MarkerId('driverMarker'),
            position: driverLatLng,
            infoWindow: const InfoWindow(title: 'Your Location'),
          ),
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
    );
  }
}