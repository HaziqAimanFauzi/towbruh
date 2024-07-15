import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:towbruh/message/chat_page.dart';

class MessagePage extends StatefulWidget {
  @override
  _MessagePageState createState() => _MessagePageState();
}

class _MessagePageState extends State<MessagePage> {
  final _currentUser = FirebaseAuth.instance.currentUser!;
  late Stream<QuerySnapshot> _chats;

  @override
  void initState() {
    super.initState();
    _chats = FirebaseFirestore.instance
        .collection('chatRooms')
        .where('participants', arrayContains: _currentUser.uid)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          automaticallyImplyLeading: false, // Removes the back button
          backgroundColor: Colors.orange[500],
          title: const Text('Messages')),
      body: StreamBuilder<QuerySnapshot>(
        stream: _chats,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text('No messages yet.'),
            );
          }
          final chatRooms = snapshot.data!.docs;
          return ListView.builder(
            itemCount: chatRooms.length,
            itemBuilder: (context, index) {
              final chatRoom = chatRooms[index];
              final List<dynamic> participants = List.from(chatRoom['participants']);
              participants.remove(_currentUser.uid);
              if (participants.isEmpty) {
                return SizedBox.shrink(); // Skip empty chat rooms
              }
              final String recipientId = participants.first;
              // Fetch user data for recipientId here
              // Example: Replace this with actual data fetching logic
              Map<String, dynamic> user = {}; // Placeholder for user data
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(recipientId).get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return SizedBox.shrink(); // Skip if user data not found
                  }
                  user = snapshot.data!.data() as Map<String, dynamic>;
                  return ListTile(
                    title: Text('Chat with: ${user['name']}'), // Use recipient's name
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatPage(
                            chatRoomId: chatRoom.id,
                            recipientId: recipientId,
                            user: user,
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
    );
  }
}
