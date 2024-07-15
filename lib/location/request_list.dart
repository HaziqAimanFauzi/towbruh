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
        backgroundColor: Colors.lightBlue[500],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('requests')
                  .where('status', isEqualTo: 'pending')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                final requests = snapshot.data!.docs;

                if (requests.isEmpty) {
                  return Center(
                    child: Text('No pending requests.'),
                  );
                }

                return ListView.builder(
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    final request = requests[index];
                    final data = request.data() as Map<String, dynamic>;

                    return FutureBuilder<DocumentSnapshot>(
                      future: _firestore
                          .collection('users')
                          .doc(data['customerId'])
                          .get(),
                      builder: (context, customerSnapshot) {
                        if (customerSnapshot.connectionState == ConnectionState.waiting) {
                          return ListTile(
                            title: Text('Loading customer...'),
                          );
                        }

                        if (!customerSnapshot.hasData || !customerSnapshot.data!.exists) {
                          return ListTile(
                            title: Text('Customer not found'),
                            subtitle: Text(data['details'] ?? 'Details not available'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.check),
                                  onPressed: () {
                                    _handleAcceptRequest(request);
                                  },
                                ),
                                IconButton(
                                  icon: Icon(Icons.close),
                                  onPressed: () {
                                    _handleRejectRequest(request);
                                  },
                                ),
                              ],
                            ),
                          );
                        }

                        final customerData = customerSnapshot.data!.data() as Map<String, dynamic>;

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: customerData['profile_image'] != null
                                ? NetworkImage(customerData['profile_image'] as String)
                                : AssetImage('assets/default_profile.png') as ImageProvider,
                          ),
                          title: Text(customerData['name'] ?? 'Unknown Customer'),
                          subtitle: Text(data['details'] ?? 'Details not available'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.check),
                                onPressed: () {
                                  _handleAcceptRequest(request);
                                },
                              ),
                              IconButton(
                                icon: Icon(Icons.close),
                                onPressed: () {
                                  _handleRejectRequest(request);
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          Divider(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('requests')
                  .where('status', isEqualTo: 'accepted')
                  .where('driverId', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                final requests = snapshot.data!.docs;

                if (requests.isEmpty) {
                  return Center(
                    child: Text('No accepted requests.'),
                  );
                }

                return ListView.builder(
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    final request = requests[index];
                    final data = request.data() as Map<String, dynamic>;

                    return FutureBuilder<DocumentSnapshot>(
                      future: _firestore
                          .collection('users')
                          .doc(data['customerId'])
                          .get(),
                      builder: (context, customerSnapshot) {
                        if (customerSnapshot.connectionState == ConnectionState.waiting) {
                          return ListTile(
                            title: Text('Loading customer...'),
                          );
                        }

                        if (!customerSnapshot.hasData || !customerSnapshot.data!.exists) {
                          return ListTile(
                            title: Text('Customer not found'),
                            subtitle: Text(data['details'] ?? 'Details not available'),
                          );
                        }

                        final customerData = customerSnapshot.data!.data() as Map<String, dynamic>;

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: customerData['profile_image'] != null
                                ? NetworkImage(customerData['profile_image'] as String)
                                : AssetImage('assets/default_profile.png') as ImageProvider,
                          ),
                          title: Text(customerData['name'] ?? 'Unknown Customer'),
                          subtitle: Text(data['details'] ?? 'Details not available'),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatPage(
                                  chatRoomId: data['chatRoomId'], // Ensure 'chatRoomId' is present in the document
                                  user: {
                                    'name': customerData['name'],
                                    'id': data['customerId'],
                                  },
                                  recipientId: data['customerId'],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _handleAcceptRequest(DocumentSnapshot request) {
    final data = request.data() as Map<String, dynamic>;

    _firestore.collection('requests').doc(request.id).update({
      'status': 'accepted',
      'driverId': FirebaseAuth.instance.currentUser!.uid,
    }).then((_) {
      if (data.containsKey('chatRoomId')) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatPage(
              chatRoomId: data['chatRoomId'],
              user: {
                'name': data['customerName'],
                'id': data['customerId'],
              },
              recipientId: data['customerId'],
            ),
          ),
        );
      } else {
        // Handle case where chatRoomId is missing or null
        print('Error: chatRoomId is missing in the request document.');
        // Optionally show a snackbar or dialog to inform the user
      }
    }).catchError((error) {
      print('Error accepting request: $error');
      // Handle error, optionally show a snackbar or dialog
    });
  }

  void _handleRejectRequest(DocumentSnapshot request) {
    _firestore.collection('requests').doc(request.id).update({
      'status': 'rejected',
    }).catchError((error) {
      print('Error rejecting request: $error');
      // Handle error, optionally show a snackbar or dialog
    });
  }
}
