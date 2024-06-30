import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DriverRequestsPage extends StatefulWidget {
  @override
  _DriverRequestsPageState createState() => _DriverRequestsPageState();
}

class _DriverRequestsPageState extends State<DriverRequestsPage> {
  final CollectionReference _requests = FirebaseFirestore.instance.collection('requests');

  void _acceptRequest(String requestId) async {
    await _requests.doc(requestId).update({'status': 'accepted'});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Driver Requests')),
      body: StreamBuilder<QuerySnapshot>(
        stream: _requests.where('status', isEqualTo: 'pending').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }
          final requests = snapshot.data!.docs;
          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              return ListTile(
                title: Text('Request from customer: ${request['customer_id']}'),
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
