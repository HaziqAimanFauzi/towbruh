import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TowDriverHomePage extends StatefulWidget {
  @override
  _TowDriverHomePageState createState() => _TowDriverHomePageState();
}

class _TowDriverHomePageState extends State<TowDriverHomePage> {
  List<Map<String, dynamic>> nearbyCustomers = [];

  @override
  void initState() {
    super.initState();
    GeofencingService().startGeofencing();
    _getNearbyCustomers();
  }

  Future<void> _getNearbyCustomers() async {
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('customers').get();

    List<Map<String, dynamic>> customers = snapshot.docs.map((doc) {
      return {
        'name': doc['name'],
        'location': doc['location'],
      };
    }).toList();

    setState(() {
      nearbyCustomers = customers.where((customer) {
        double distance = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          customer['location'].latitude,
          customer['location'].longitude,
        );
        return distance <= 1000; // 1 km radius
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Nearby Customers'),
      ),
      body: ListView.builder(
        itemCount: nearbyCustomers.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(nearbyCustomers[index]['name']),
            subtitle: Text('Distance: ${(nearbyCustomers[index]['distance'] / 1000).toStringAsFixed(2)} km'),
          );
        },
      ),
    );
  }
}
