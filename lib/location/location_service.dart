import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  final _currentUser = FirebaseAuth.instance.currentUser!;
  final CollectionReference _locations = FirebaseFirestore.instance.collection('locations');

  void startLocationUpdates() async {
    Geolocator.getPositionStream(locationSettings: LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10)).listen((Position position) {
      _locations.doc(_currentUser.uid).set({
        'latitude': position.latitude,
        'longitude': position.longitude,
        'timestamp': FieldValue.serverTimestamp(),
      });
    });
  }
}
