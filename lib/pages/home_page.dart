import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:towbruh/pages/customer_profile.dart';
import 'package:towbruh/pages/tow_profile.dart';
import 'package:towbruh/pages/message_page.dart';

class HomePage extends StatefulWidget {
  final String userRole;

  const HomePage({Key? key, required this.userRole}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  late GoogleMapController _mapController;
  LatLng _initialPosition = const LatLng(45.521563, -122.677433);
  LatLng _currentPosition = const LatLng(45.521563, -122.677433);
  bool _locationPermissionGranted = false;
  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};
  late StreamSubscription<DocumentSnapshot> _driverSubscription;
  late PolylinePoints _polylinePoints;
  final String googleApiKey = 'YOUR_API_KEY';
  List<QueryDocumentSnapshot> _nearbyRequests = [];

  final List<Widget> _widgetOptionsCustomer = [
    const Text('Home Page Content'),
    MessagePage(),
    CustomerProfilePage(),
  ];

  final List<Widget> _widgetOptionsTow = [
    const Text('Home Page Content'),
    MessagePage(),
    TowProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    _polylinePoints = PolylinePoints();
    _checkLocationPermission();
    if (widget.userRole == 'driver') {
      _fetchNearbyRequests();
    }
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
        desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _currentPosition = LatLng(position.latitude, position.longitude);
      _initialPosition = _currentPosition;
      if (widget.userRole == 'customer') {
        _addCustomerMarker();
      }
    });
  }

  Future<void> _fetchNearbyRequests() async {
    FirebaseFirestore.instance
        .collection('requests')
        .snapshots()
        .listen((snapshot) {
      setState(() {
        _nearbyRequests = snapshot.docs;
      });
    });
  }

  Future<void> _createPolylines(LatLng start, LatLng destination) async {
    PolylineResult result = await _polylinePoints.getRouteBetweenCoordinates(
      googleApiKey,
      PointLatLng(start.latitude, start.longitude),
      PointLatLng(destination.latitude, destination.longitude),
    );

    if (result.points.isNotEmpty) {
      setState(() {
        _polylines.add(Polyline(
          polylineId: const PolylineId('polyline'),
          color: Colors.blue,
          width: 5,
          points: result.points
              .map((point) => LatLng(point.latitude, point.longitude))
              .toList(),
        ));
      });
    }
  }

  void _addCustomerMarker() {
    setState(() {
      _markers.add(Marker(
        markerId: const MarkerId('customerMarker'),
        position: _currentPosition,
        infoWindow: const InfoWindow(title: 'Your Location'),
      ));
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
    await FirebaseFirestore.instance.collection('requests').add({
      'customer_id': FirebaseAuth.instance.currentUser!.uid,
      'location': GeoPoint(_currentPosition.latitude, _currentPosition.longitude),
      'status': 'pending',
    });
    _showRequestBottomSheet();
  }

  void _showRequestBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Request Sent',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            const Text(
              'Waiting for a driver to accept your request.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      ),
    );
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
                zoom: 11.0,
              ),
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              markers: _markers,
              polylines: _polylines,
            ),
            if (widget.userRole == 'customer')
              Positioned(
                bottom: 20,
                left: MediaQuery.of(context).size.width * 0.25,
                child: ElevatedButton(
                  onPressed: _requestDriver,
                  child: const Text('Request Driver'),
                ),
              ),
            if (widget.userRole == 'driver')
              for (var request in _nearbyRequests)
                Positioned(
                  top: MediaQuery.of(context).size.height / 2,
                  left: MediaQuery.of(context).size.width / 2,
                  child: GestureDetector(
                    onTap: () async {
                      await FirebaseFirestore.instance
                          .collection('requests')
                          .doc(request.id)
                          .update({'status': 'accepted', 'driver_id': FirebaseAuth.instance.currentUser!.uid});
                      _createPolylines(_currentPosition, LatLng(request['location'].latitude, request['location'].longitude));
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8.0),
                      color: Colors.white,
                      child: const Text('Accept Request'),
                    ),
                  ),
                ),
          ],
        )
            : const Text('Location permission not granted')
            : widget.userRole == 'customer'
            ? _widgetOptionsCustomer.elementAt(_selectedIndex)
            : _widgetOptionsTow.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message),
            label: 'Message',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[800],
        onTap: _onItemTapped,
        selectedFontSize: 14.0,
        unselectedFontSize: 12.0,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
      ),
    );
  }
}
