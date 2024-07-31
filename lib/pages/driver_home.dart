import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart' as polyline_points;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:towbruh/message/message_page.dart';
import 'package:towbruh/pages/profile_page.dart';
import 'package:towbruh/location/request_list.dart';

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
  late polyline_points.PolylinePoints _polylinePoints;
  final String googleApiKey = 'AIzaSyAMR2JS44EhS0ktzAM4aWAl5zA93vjjiWQ';
  late StreamSubscription<QuerySnapshot> _requestSubscription;
  LatLng? _customerLocation;
  String? _requestId;
  double _distanceToCustomer = 0;

  final List<Widget> _widgetOptionsDriver = [
    const Text('Home Page Content'),
    MessagePage(),
    ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    _polylinePoints = polyline_points.PolylinePoints();
    _checkLocationPermission();
    _startListeningToRequestUpdates();
    _updateDriverLocation();
  }

  @override
  void dispose() {
    _requestSubscription.cancel();
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

  void _startListeningToRequestUpdates() {
    _requestSubscription = FirebaseFirestore.instance
        .collection('requests')
        .where('driver_id', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
        .where('status', isEqualTo: 'accepted_by_driver')
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        final request = snapshot.docs.first;
        final data = request.data() as Map<String, dynamic>;

        setState(() {
          _customerLocation = LatLng(
            (data['location'] as GeoPoint).latitude,
            (data['location'] as GeoPoint).longitude,
          );
          _requestId = request.id;
          _createPolylines(_currentPosition, _customerLocation!);
          _addCustomerMarker(_customerLocation!);
          _calculateDistance();
        });
      }
    });
  }

  Future<void> _createPolylines(LatLng start, LatLng destination) async {
    polyline_points.PolylineResult result = await _polylinePoints.getRouteBetweenCoordinates(
      googleApiKey,
      polyline_points.PointLatLng(start.latitude, start.longitude),
      polyline_points.PointLatLng(destination.latitude, destination.longitude),
      travelMode: polyline_points.TravelMode.driving,
    );

    if (result.points.isNotEmpty) {
      List<LatLng> polylineCoordinates = [];
      for (var point in result.points) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      }

      setState(() {
        _polylines.add(
          Polyline(
            polylineId: PolylineId('poly'),
            color: Colors.blue,
            points: polylineCoordinates,
            width: 5,
          ),
        );
      });
    }
  }

  void _addCustomerMarker(LatLng position) {
    setState(() {
      _markers.add(
        Marker(
          markerId: const MarkerId('customerMarker'),
          position: position,
          infoWindow: const InfoWindow(title: 'Customer Location'),
        ),
      );
    });
  }

  void _calculateDistance() {
    if (_customerLocation != null) {
      setState(() {
        _distanceToCustomer = Geolocator.distanceBetween(
          _currentPosition.latitude,
          _currentPosition.longitude,
          _customerLocation!.latitude,
          _customerLocation!.longitude,
        );
      });
    }
  }

  void _navigateToRequestList() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => RequestListPage()),
    );
  }

  void _updateDriverLocation() {
    Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update location if moved by 10 meters
      ),
    ).listen((Position position) {
      if (position != null) {
        FirebaseFirestore.instance.collection('drivers').doc(FirebaseAuth.instance.currentUser!.uid).update({
          'location': GeoPoint(position.latitude, position.longitude),
        });
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
          _addDriverMarker();
          _calculateDistance();
          if (_distanceToCustomer <= 100) {
            _notifyCustomerDriverArrival();
          }
        });
      }
    });
  }

  void _notifyCustomerDriverArrival() {
    if (_requestId != null && _customerLocation != null) {
      FirebaseFirestore.instance.collection('requests').doc(_requestId).update({
        'status': 'driver_arrived',
      });

      FirebaseFirestore.instance.collection('chatRooms').where('participants', arrayContains: FirebaseAuth.instance.currentUser!.uid).get().then((querySnapshot) {
        if (querySnapshot.docs.isNotEmpty) {
          DocumentSnapshot chatRoom = querySnapshot.docs.first;
          FirebaseFirestore.instance.collection('chatRooms').doc(chatRoom.id).collection('messages').add({
            'sender': FirebaseAuth.instance.currentUser!.uid,
            'message': 'The driver has arrived at your location.',
            'timestamp': FieldValue.serverTimestamp(),
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orange[500],
        title: Text('Driver Home'),
        automaticallyImplyLeading: false,
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
            if (_customerLocation != null)
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: Container(
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
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Customer Location', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      Text('Latitude: ${_customerLocation!.latitude}'),
                      Text('Longitude: ${_customerLocation!.longitude}'),
                      Text('Distance to Customer: ${(_distanceToCustomer / 1000).toStringAsFixed(2)} km'),
                    ],
                  ),
                ),
              ),
          ],
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
        backgroundColor: Colors.blue,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
    );
  }
}
