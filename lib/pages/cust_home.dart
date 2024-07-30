import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_google_maps_webservices/places.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_places_for_flutter_3/google_places_for_flutter_3.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart' as polyline_points;
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
  LatLng _initialPosition = const LatLng(3.1390, 101.6869); // Default to Kuala Lumpur
  LatLng _currentPosition = const LatLng(3.1390, 101.6869);
  bool _locationPermissionGranted = false;
  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};
  late polyline_points.PolylinePoints _polylinePoints;
  final String googleApiKey = 'AIzaSyAMR2JS44EhS0ktzAM4aWAl5zA93vjjiWQ';
  String? _driverId;
  StreamSubscription<DocumentSnapshot>? _driverLocationSubscription;
  String? _userRole;
  Map<String, dynamic>? _driverData; // Added to store driver data
  String? _requestId; // Store request ID
  Timer? _countdownTimer;
  int _countdown = 30;
  LatLng? _selectedWorkshopLocation; // Selected workshop location
  late GoogleMapsPlaces _places; // Initialize Google Places API

  final List<Widget> _widgetOptionsCustomer = [
    const Text('Home Page Content'),
    MessagePage(),
    ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    _places = GoogleMapsPlaces(apiKey: googleApiKey);
    _polylinePoints = polyline_points.PolylinePoints();
    _checkLocationPermission();
    _fetchUserRole();
    _loadNearbyWorkshops();
  }

  @override
  void dispose() {
    _driverLocationSubscription?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkLocationPermission() async {
    var status = await Permission.location.status;
    if (status.isDenied) {
      status = await Permission.location.request();
    }

    if (status.isGranted) {
      setState(() {
        _locationPermissionGranted = true;
      });
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
    _loadNearbyWorkshops(); // Load workshops when the map is created
  }

  Future<void> _loadNearbyWorkshops() async {
    if (_locationPermissionGranted) {
      final response = await _places.searchNearbyWithRadius(
        Location(lat: _currentPosition.latitude, lng: _currentPosition.longitude),
        50000,
        type: 'car_repair', // Search for car repair workshops
      );

      if (response.status == 'OK') {
        print('Workshops found: ${response.results.length}'); // Log number of workshops found
        setState(() {
          _markers.addAll(response.results.map((result) {
            return Marker(
              markerId: MarkerId(result.placeId),
              position: LatLng(result.geometry!.location.lat, result.geometry!.location.lng),
              infoWindow: InfoWindow(
                title: result.name,
                snippet: result.vicinity,
              ),
            );
          }).toList());
        });
      } else {
        print('Error loading nearby workshops: ${response.errorMessage}');
      }
    } else {
      print('Location permission not granted');
    }
  }

  Future<void> _requestDriver() async {
    if (_userRole != 'customer') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Only customers can request a driver.')),
      );
      return;
    }

    if (_selectedWorkshopLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a workshop first.')),
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
        'workshop_location': GeoPoint(
          _selectedWorkshopLocation!.latitude,
          _selectedWorkshopLocation!.longitude,
        ),
        'status': 'pending',
      },
    );

    setState(() {
      _requestId = requestRef.id;
    });

    _showRequestSentDialog();
    _startCountdown();
    _listenForDriverAcceptance();
  }

  void _showRequestSentDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request Sent'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Waiting for a driver to accept your request.'),
            SizedBox(height: 20),
            Text('Time remaining: $_countdown seconds'),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _cancelRequest,
              child: Text('Cancel Request'),
            ),
          ],
        ),
      ),
    );
  }

  void _startCountdown() {
    _countdown = 30;
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_countdown == 0) {
        timer.cancel();
        Navigator.pop(context);
      } else {
        setState(() {
          _countdown--;
        });
      }
    });
  }

  void _cancelRequest() async {
    await FirebaseFirestore.instance.collection('requests').doc(_requestId).delete();
    Navigator.pop(context);
  }

  void _listenForDriverAcceptance() {
    FirebaseFirestore.instance.collection('requests').doc(_requestId).snapshots().listen((snapshot) {
      if (snapshot.exists && snapshot.data()?['status'] == 'accepted_by_driver') {
        setState(() {
          _driverId = snapshot.data()?['driver_id'];
        });
        _fetchDriverData(snapshot.data()?['driver_id']); // Fetch driver data
        _showDriverAcceptanceDialog();
      }
    });
  }

  Future<void> _fetchDriverData(String? driverId) async {
    if (driverId == null) return;
    DocumentSnapshot driverDoc = await FirebaseFirestore.instance.collection('users').doc(driverId).get();
    setState(() {
      _driverData = driverDoc.data() as Map<String, dynamic>?;
    });
  }

  void _showDriverAcceptanceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Driver Accepted Your Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: ${_driverData!['name']}'),
            Text('Phone: ${_driverData!['phone']}'),
            Text('Number Plate: ${_driverData!['number_plate']}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _acceptDriver();
            },
            child: const Text('Accept'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _rejectDriver();
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  Future<void> _acceptDriver() async {
    await FirebaseFirestore.instance.collection('requests').doc(_requestId).update({
      'status': 'accepted_by_customer',
    });

    _startTrackingDriverLocation();
    _createChatRoom(_driverId!);
  }

  Future<void> _rejectDriver() async {
    await FirebaseFirestore.instance.collection('requests').doc(_requestId).update({
      'status': 'rejected_by_customer',
    });

    setState(() {
      _driverId = null;
      _driverData = null;
      _requestId = null;
    });
  }

  Future<void> _createChatRoom(String driverId) async {
    final currentUser = FirebaseAuth.instance.currentUser!;
    DocumentReference chatRoomRef = await FirebaseFirestore.instance
        .collection('chatRooms')
        .where('participants', arrayContains: currentUser.uid)
        .get()
        .then((querySnapshot) {
      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.reference;
      } else {
        return FirebaseFirestore.instance.collection('chatRooms').add({
          'participants': [currentUser.uid, driverId],
          'lastMessage': '',
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
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

          // Create polylines
          _createPolylines(_currentPosition, driverLatLng);
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
      result.points.forEach((polyline_points.PointLatLng point) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      });

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

  Future<void> _searchWorkshop() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Workshop'),
        content: SearchGooglePlacesWidget(
          apiKey: googleApiKey,
          placeType: PlaceType.establishment,
          placeholder: 'Enter workshop location',
          language: 'en',
          location: LatLng(_currentPosition.latitude, _currentPosition.longitude),
          radius: 30000,
          onSearch: (Place place) {},
          onSelected: (Place place) async {
            final geolocation = await place.geolocation;
            setState(() {
              _selectedWorkshopLocation = LatLng(geolocation!.coordinates.latitude, geolocation.coordinates.longitude);
              _markers.add(
                Marker(
                  markerId: MarkerId(place.placeId!),
                  position: _selectedWorkshopLocation!,
                  infoWindow: InfoWindow(title: place.description),
                ),
              );
            });
            _mapController.animateCamera(
              CameraUpdate.newLatLng(_selectedWorkshopLocation!),
            );
            Navigator.pop(context); // Close the dialog after selecting
          },
        ),
      ),
    );
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
        backgroundColor: Colors.orange[500],
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
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.search, color: Colors.white),
                      onPressed: _searchWorkshop,
                      tooltip: 'Search Workshop',
                    ),
                  ),
                  const SizedBox(width: 100),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.done, color: Colors.white),
                      onPressed: _requestDriver,
                      tooltip: 'Request Driver',
                    ),
                  ),
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
