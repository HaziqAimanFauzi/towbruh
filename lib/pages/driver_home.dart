import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:towbruh/message/message_page.dart';
import 'package:towbruh/pages/profile_page.dart';
import 'package:towbruh/location/request_list.dart'; // Import the request list page

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
    _listenForRequests();
    _loadChatRooms(); // Initialize chat room stream
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

  void _acceptRequest(String requestId, GeoPoint customerLocation) async {
    await FirebaseFirestore.instance.collection('requests').doc(requestId).update({
      'status': 'accepted',
      'driver_id': FirebaseAuth.instance.currentUser!.uid,
    });

    _showRequestAcceptedDialog();
    _addCustomerMarker(customerLocation);
    _startTrackingDriverLocation();
    _setRouteToCustomer(LatLng(customerLocation.latitude, customerLocation.longitude));
  }

  void _showRequestAcceptedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Request Accepted'),
          content: Text('You have accepted the customer\'s request.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _addCustomerMarker(GeoPoint customerLocation) {
    LatLng customerLatLng = LatLng(customerLocation.latitude, customerLocation.longitude);
    setState(() {
      _markers.add(
        Marker(
          markerId: const MarkerId('customerMarker'),
          position: customerLatLng,
          infoWindow: const InfoWindow(title: 'Customer Location'),
        ),
      );
    });
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

  void _setRouteToCustomer(LatLng customerLatLng) {
    // Implement logic to set route or polyline to customer's location
    // Example using PolylinePoints and Google Maps:
    // _polylinePoints.add(...);
    // _polylines.add(...);
  }

  void _loadChatRooms() {
    _chats = FirebaseFirestore.instance
        .collection('chatRooms')
        .where('participants', arrayContains: FirebaseAuth.instance.currentUser!.uid)
        .snapshots();
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
            Positioned(
              bottom: 20,
              right: 20,
              child: FloatingActionButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => RequestListPage()),
                  );
                },
                child: Icon(Icons.list),
              ),
            ),
          ],
        )
            : const Text('Location permission not granted')
            : _widgetOptionsDriver.elementAt(_selectedIndex),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'Drawer Header',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              title: Text('Item 1'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('Item 2'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
