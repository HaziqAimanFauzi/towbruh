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
    _requestSubscription = FirebaseFirestore.instance
        .collection('requests')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .listen((snapshot) {
      for (var document in snapshot.docs) {
        // Handle new pending requests
        _showRequestDialog(document.id, document['location']);
      }
    });
  }

  void _showRequestDialog(String requestId, GeoPoint customerLocation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Request'),
        content: const Text('A customer is requesting a driver.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Ignore'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _acceptRequest(requestId, customerLocation);
            },
            child: const Text('Accept'),
          ),
        ],
      ),
    );
  }

  Future<void> _acceptRequest(String requestId, GeoPoint customerLocation) async {
    await FirebaseFirestore.instance.collection('requests').doc(requestId).update(
      {
        'driver_id': FirebaseAuth.instance.currentUser!.uid,
        'status': 'accepted',
      },
    );
    _showRequestAcceptedDialog();
    _addCustomerMarker(customerLocation);
    _updateDriverLocation();
    _setRouteToCustomer(LatLng(customerLocation.latitude, customerLocation.longitude));
  }

  void _showRequestAcceptedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request Accepted'),
        content: const Text('You have accepted the customer\'s request.'),
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

  void _addCustomerMarker(GeoPoint customerLocation) {
    setState(() {
      _markers.add(
        Marker(
          markerId: const MarkerId('customerMarker'),
          position: LatLng(customerLocation.latitude, customerLocation.longitude),
          infoWindow: const InfoWindow(title: 'Customer Location'),
        ),
      );
    });
  }

  Future<void> _updateDriverLocation() async {
    await FirebaseFirestore.instance.collection('drivers').doc(FirebaseAuth.instance.currentUser!.uid).update(
      {
        'location': GeoPoint(_currentPosition.latitude, _currentPosition.longitude),
      },
    );
  }

  Future<void> _setRouteToCustomer(LatLng customerLatLng) async {
    List<LatLng> polylineCoordinates = [];
    PolylineResult result = await _polylinePoints.getRouteBetweenCoordinates(
      googleApiKey,
      PointLatLng(_currentPosition.latitude, _currentPosition.longitude),
      PointLatLng(customerLatLng.latitude, customerLatLng.longitude),
    );

    if (result.points.isNotEmpty) {
      result.points.forEach((PointLatLng point) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      });
    } else {
      print(result.errorMessage);
    }

    setState(() {
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          width: 5,
          color: Colors.blue,
          points: polylineCoordinates,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          ],
        )
            : const Text('Location permission not granted')
            : _widgetOptionsDriver.elementAt(_selectedIndex),
      ),
    );
  }
}
