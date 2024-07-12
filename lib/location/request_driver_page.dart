import 'package:flutter/material.dart';
import 'package:geofence_service/geofence_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';

// Add aliases to the import statements
import 'package:fl_location_platform_interface/src/models/location_accuracy.dart' as fl;
import 'package:geolocator_platform_interface/src/enums/location_accuracy.dart' as geo;

class RequestDriverPage extends StatefulWidget {
  @override
  _RequestDriverPageState createState() => _RequestDriverPageState();
}

class _RequestDriverPageState extends State<RequestDriverPage> {
  late GoogleMapController mapController;
  Set<Circle> circles = Set();
  LatLng _currentPosition = LatLng(45.521563, -122.677433); // Default position
  late GeofenceService _geofenceService; // Geofence service instance
  String geofenceId = 'myGeofence';

  final StreamController<Geofence> _geofenceStreamController = StreamController<Geofence>();
  final StreamController<Activity> _activityStreamController = StreamController<Activity>();

  @override
  void initState() {
    super.initState();
    requestPermissions(); // Request permissions
    _getCurrentLocation();
    _setupGeofenceService();
  }

  void requestPermissions() async {
    await [
      Permission.location,
      Permission.locationAlways,
    ].request();
  }

  void _setupGeofenceService() {
    _geofenceService = GeofenceService.instance.setup(
      interval: 5000,
      accuracy: 100,
      loiteringDelayMs: 60000,
      statusChangeDelayMs: 10000,
      useActivityRecognition: true,
      allowMockLocations: false,
      printDevLog: false,
      geofenceRadiusSortType: GeofenceRadiusSortType.DESC,
    );

    // Register listeners
    _geofenceService.addGeofenceStatusChangeListener(_onGeofenceStatusChanged);
    _geofenceService.addLocationChangeListener(_onLocationChanged);
    _geofenceService.addLocationServicesStatusChangeListener(_onLocationServicesStatusChanged);
    _geofenceService.addActivityChangeListener(_onActivityChanged);
    _geofenceService.addStreamErrorListener(_onError);

    // Start geofence service
    _geofenceService.start(_geofenceList).catchError(_onError);
  }

  Future<void> _onGeofenceStatusChanged(
      Geofence geofence,
      GeofenceRadius geofenceRadius,
      GeofenceStatus geofenceStatus,
      Location location) async {
    print('geofence: ${geofence.toJson()}');
    print('geofenceRadius: ${geofenceRadius.toJson()}');
    print('geofenceStatus: ${geofenceStatus.toString()}');
    _geofenceStreamController.sink.add(geofence);
  }

  void _onActivityChanged(Activity prevActivity, Activity currActivity) {
    print('prevActivity: ${prevActivity.toJson()}');
    print('currActivity: ${currActivity.toJson()}');
    _activityStreamController.sink.add(currActivity);
  }

  void _onLocationChanged(Location location) {
    print('location: ${location.toJson()}');
  }

  void _onLocationServicesStatusChanged(bool status) {
    print('isLocationServicesEnabled: $status');
  }

  void _onError(error) {
    final errorCode = getErrorCodesFromError(error);
    if (errorCode == null) {
      print('Undefined error: $error');
      return;
    }

    print('ErrorCode: $errorCode');
  }

  void _getCurrentLocation() async {
    // Use the geo alias for LocationAccuracy
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: geo.LocationAccuracy.high);
    setState(() {
      _currentPosition = LatLng(position.latitude, position.longitude);
    });
  }

  final List<Geofence> _geofenceList = <Geofence>[
    Geofence(
      id: 'place_1',
      latitude: 35.103422,
      longitude: 129.036023,
      radius: [
        GeofenceRadius(id: 'radius_100m', length: 100),
        GeofenceRadius(id: 'radius_25m', length: 25),
        GeofenceRadius(id: 'radius_250m', length: 250),
        GeofenceRadius(id: 'radius_200m', length: 200),
      ],
    ),
    Geofence(
      id: 'place_2',
      latitude: 35.104971,
      longitude: 129.034851,
      radius: [
        GeofenceRadius(id: 'radius_25m', length: 25),
        GeofenceRadius(id: 'radius_100m', length: 100),
        GeofenceRadius(id: 'radius_200m', length: 200),
      ],
    ),
  ];

  void _setupGeofence() {
    final radius = GeofenceRadius(id: 'radius_500m', length: 500.0); // Radius in meters

    final geofence = Geofence(
      id: geofenceId,
      latitude: _currentPosition.latitude,
      longitude: _currentPosition.longitude,
      radius: [radius], // Radius as a list
    );

    try {
      _geofenceService.addGeofence(geofence);
      print('Geofence added: ${geofence.id}');
    } catch (e) {
      print('Failed to add geofence: $e');
    }

    // Creating a circle on the map to visualize the geofence
    circles.add(
      Circle(
        circleId: CircleId(geofenceId),
        center: _currentPosition,
        radius: radius.length,
        fillColor: Colors.blue.withOpacity(0.2),
        strokeColor: Colors.blue,
        strokeWidth: 2,
      ),
    );

    setState(() {});
  }

  @override
  void dispose() {
    // Unregister listeners
    _geofenceService.removeGeofenceStatusChangeListener(_onGeofenceStatusChanged);
    _geofenceService.removeLocationChangeListener(_onLocationChanged);
    _geofenceService.removeLocationServicesStatusChangeListener(_onLocationServicesStatusChanged);
    _geofenceService.removeActivityChangeListener(_onActivityChanged);
    _geofenceService.removeStreamErrorListener(_onError);
    _geofenceService.clearAllListeners();
    _geofenceService.stop();

    _geofenceStreamController.close();
    _activityStreamController.close();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Request Driver Page'),
      ),
      body: Stack(
        children: <Widget>[
          GoogleMap(
            onMapCreated: (GoogleMapController controller) {
              mapController = controller;
            },
            initialCameraPosition: CameraPosition(
              target: _currentPosition,
              zoom: 14.0,
            ),
            circles: circles,
          ),
          Positioned(
            top: 20,
            right: 20,
            child: FloatingActionButton(
              onPressed: _setupGeofence,
              tooltip: 'Set Geofence',
              child: Icon(Icons.add_location),
            ),
          ),
        ],
      ),
    );
  }
}
