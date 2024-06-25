import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DriverRequestsPage extends StatefulWidget {
  @override
  _DriverRequestsPageState createState() => _DriverRequestsPageState();
}

class _DriverRequestsPageState extends State<DriverRequestsPage> {
  final _currentUser = FirebaseAuth.instance.currentUser!;
  late CollectionReference _requests;

  @override
  void initState() {
    super.initState();
    _requests = FirebaseFirestore.instance.collection('requests');
  }

  void _acceptRequest(String requestId) async {
    await _requests.doc(requestId).update({'status': 'accepted', 'driver_id': _currentUser.uid});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Driver Requests')),
      body: StreamBuilder<QuerySnapshot>(
        stream: _requests.where('status', isEqualTo: 'pending').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return CircularProgressIndicator();

          final requests = snapshot.data!.docs;

          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              return ListTile(
                title: Text('Request from ${request['customer_id']}'),
                trailing: ElevatedButton(
                  onPressed: () => _acceptRequest(request.id),
                  child: Text('Accept'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
