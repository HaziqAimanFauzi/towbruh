import 'package:geofencing/geofencing.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GeofencingService {
  void startGeofencing() async {
    List<GeofenceEvent> triggers = [GeofenceEvent.enter, GeofenceEvent.exit];
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

    Geofence.initialize();
    Geofence.addGeofence(
      GeofenceRegion(
        'customer_geofence',
        position.latitude,
        position.longitude,
        1000, // radius in meters
        triggers,
        androidSettings: AndroidGeofencingSettings(
          initialTrigger: <GeofenceEvent>[GeofenceEvent.enter, GeofenceEvent.exit],
          loiteringDelay: 60000,
          notificationResponsiveness: 10000,
        ),
        iosSettings: IOSGeofencingSettings(
          notifyOnEntry: true,
          notifyOnExit: true,
          notifyOnDwell: false,
        ),
      ),
      callback,
    );
  }

  static Future<void> callback(List<String> id, Location l, GeofenceEvent e) async {
    // handle geofence event
    // You can send a notification or update the UI
  }
}
