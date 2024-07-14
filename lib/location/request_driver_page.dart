import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:towbruh/location/request_list.dart';

class RequestDriverPage extends StatefulWidget {
  @override
  _RequestDriverPageState createState() => _RequestDriverPageState();
}

class _RequestDriverPageState extends State<RequestDriverPage> {
  late GoogleMapController mapController;
  LatLng _currentPosition = LatLng(45.521563, -122.677433); // Default position

  @override
  void initState() {
    super.initState();
    requestPermissions(); // Request permissions
    _getCurrentLocation();
  }

  void requestPermissions() async {
    await [
      Permission.location,
      Permission.locationAlways,
    ].request();
  }

  void _getCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _currentPosition = LatLng(position.latitude, position.longitude);
    });
  }

  void _navigateToRequestList() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => RequestListPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Request Driver Page'),
      ),
      body: GoogleMap(
        onMapCreated: (GoogleMapController controller) {
          mapController = controller;
        },
        initialCameraPosition: CameraPosition(
          target: _currentPosition,
          zoom: 14.0,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToRequestList,
        tooltip: 'View Requests',
        child: Icon(Icons.list),
      ),
    );
  }
}
