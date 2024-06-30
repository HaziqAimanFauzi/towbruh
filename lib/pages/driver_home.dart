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

class TowDriverHomePage extends StatefulWidget {
  const TowDriverHomePage({Key? key}) : super(key: key);

  @override
  _TowDriverHomePageState createState() => _TowDriverHomePageState();
}

class _TowDriverHomePageState extends State<TowDriverHomePage> {
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

  final List<Widget> _widgetOptionsTow = [
    const Text('Home Page Content'),
    MessagePage(),
    ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    _polylinePoints = PolylinePoints();
    _checkLocationPermission();
    _fetchNearbyRequests();
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
      _addTowDriverMarker();
    });
  }

  void _addTowDriverMarker() {
    setState(() {
      _markers.add(
        Marker(
          markerId: const MarkerId('towDriverMarker'),
          position: _currentPosition,
          infoWindow: const InfoWindow(title: 'Your Location'),
        ),
      );
    });
  }

  Future<void> _fetchNearbyRequests() async {
    FirebaseFirestore.instance.collection('requests').snapshots().listen(
          (snapshot) {
        setState(() {
          _nearbyRequests = snapshot.docs;
        });
      },
    );
  }

  Future<void> _createPolylines(LatLng start, LatLng destination) async {
    PolylineResult result = await _polylinePoints.getRouteBetweenCoordinates(
      googleApiKey,
      PointLatLng(start.latitude, start.longitude),
      PointLatLng(destination.latitude, destination.longitude),
    );

    if (result.points.isNotEmpty) {
      setState(() {
        _polylines.add(
          Polyline(
            polylineId: const PolylineId('polyline'),
            color: Colors.blue,
            width: 5,
            points: result.points
                .map(
                  (point) => LatLng(point.latitude, point.longitude),
            )
                .toList(),
          ),
        );
      });
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _acceptRequest(QueryDocumentSnapshot request) async {
    await FirebaseFirestore.instance
        .collection('requests')
        .doc(request.id)
        .update({
      'status': 'accepted',
      'driver_id': FirebaseAuth.instance.currentUser!.uid,
    });
    _createPolylines(
      _currentPosition,
      LatLng(
        request['location'].latitude,
        request['location'].longitude,
      ),
    );
  }

  void _declineRequest(QueryDocumentSnapshot request) async {
    await FirebaseFirestore.instance
        .collection('requests')
        .doc(request.id)
        .update({
      'status': 'declined',
      'driver_id': FirebaseAuth.instance.currentUser!.uid,
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
                zoom: 11.0,
              ),
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              markers: _markers,
              polylines: _polylines,
            ),
            if (_nearbyRequests.isNotEmpty)
              Positioned(
                bottom: 20,
                left: MediaQuery.of(context).size.width * 0.25,
                child: ElevatedButton(
                  onPressed: () => _acceptRequest(_nearbyRequests.first),
                  child: const Text('Accept Request'),
                ),
              ),
          ],
        )
            : const Text('Location permission not granted')
            : _widgetOptionsTow.elementAt(_selectedIndex),
      ),
    );
  }
}
