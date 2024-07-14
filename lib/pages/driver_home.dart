import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:towbruh/message/chat_page.dart';

class DriverHomePage extends StatefulWidget {
  @override
  _DriverHomePageState createState() => _DriverHomePageState();
}

class _DriverHomePageState extends State<DriverHomePage> {
  late GoogleMapController _mapController;
  LatLng _initialPosition = const LatLng(45.521563, -122.677433);
  LatLng _currentPosition = const LatLng(45.521563, -122.677433);
  bool _locationPermissionGranted = false;
  Set<Marker> _markers = {};
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
    _fetchUserRole();
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

  Future<void> _acceptRequest(String requestId, GeoPoint customerLocation, String customerId) async {
    await FirebaseFirestore.instance.collection('requests').doc(requestId).update({
      'status': 'accepted',
      'driver_id': FirebaseAuth.instance.currentUser!.uid,
    });

    // Create a chat room between the driver and the customer
    DocumentReference chatRoomRef = await FirebaseFirestore.instance.collection('chatRooms').add({
      'participants': [FirebaseAuth.instance.currentUser!.uid, customerId],
      'lastMessage': '',
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Fetch customer details
    DocumentSnapshot customerDoc = await FirebaseFirestore.instance.collection('users').doc(customerId).get();
    Map<String, dynamic> customerData = customerDoc.data() as Map<String, dynamic>;

    _showRequestAcceptedDialog();
    _addCustomerMarker(customerLocation);
    _startTrackingDriverLocation();
    _setRouteToCustomer(LatLng(customerLocation.latitude, customerLocation.longitude));

    // Navigate to chat room
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatPage(
          chatRoomId: chatRoomRef.id,
          user: customerData,
          recipientId: customerId,
        ),
      ),
    );
  }

  void _showRequestAcceptedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request Accepted'),
        content: const Text('You have accepted the request.'),
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

  void _startTrackingDriverLocation() {
    // Add code to track driver location
  }

  void _setRouteToCustomer(LatLng customerLocation) {
    // Add code to set route to customer
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Home'),
      ),
      body: _locationPermissionGranted
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
          ),
          Positioned(
            bottom: 20,
            left: MediaQuery.of(context).size.width * 0.25,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RequestListPage(onAcceptRequest: _acceptRequest),
                  ),
                );
              },
              child: const Text('View Requests'),
            ),
          ),
        ],
      )
          : const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class RequestListPage extends StatelessWidget {
  final Function(String, GeoPoint, String) onAcceptRequest;

  RequestListPage({required this.onAcceptRequest});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Request List'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('requests').where('status', isEqualTo: 'pending').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final requests = snapshot.data!.docs;

          if (requests.isEmpty) {
            return const Center(child: Text('No requests available.'));
          }

          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              final customerLocation = request['location'];
              final customerId = request['customer_id'];

              return ListTile(
                title: Text('Request from customer $customerId'),
                subtitle: Text('Location: (${customerLocation.latitude}, ${customerLocation.longitude})'),
                trailing: ElevatedButton(
                  onPressed: () {
                    onAcceptRequest(request.id, customerLocation, customerId);
                  },
                  child: const Text('Accept'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
