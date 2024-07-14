import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:towbruh/message/chat_page.dart'; // Import the chat page

class RequestListPage extends StatefulWidget {
  @override
  _RequestListPageState createState() => _RequestListPageState();
}

class _RequestListPageState extends State<RequestListPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Request List'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('requests').where('status', isEqualTo: 'pending').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final requests = snapshot.data!.docs;

          List<Widget> requestWidgets = requests.map((request) {
            return ListTile(
              title: Text(request['customerName']),
              subtitle: Text(request['details']),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.check),
                    onPressed: () {
                      // Handle accept request
                      _firestore.collection('requests').doc(request.id).update({
                        'status': 'accepted',
                        'driverId': FirebaseAuth.instance.currentUser!.uid,
                      });
                      // Navigate to chat page
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatPage(
                            chatRoomId: request['chatRoomId'],
                            user: {
                              'name': request['customerName'],
                              'id': request['customerId'],
                            },
                            recipientId: request['customerId'],
                          ),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () {
                      // Handle reject request
                      _firestore.collection('requests').doc(request.id).update({
                        'status': 'rejected',
                      });
                    },
                  ),
                ],
              ),
            );
          }).toList();

          return ListView(
            children: requestWidgets,
          );
        },
      ),
    );
  }
}
