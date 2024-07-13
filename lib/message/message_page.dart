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
      appBar: AppBar(title: const Text('Messages')),
      body: StreamBuilder<QuerySnapshot>(
        stream: _chats,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final chatRooms = snapshot.data!.docs;
          return ListView.builder(
            itemCount: chatRooms.length,
            itemBuilder: (context, index) {
              final chatRoom = chatRooms[index];
              final List participants = chatRoom['participants'];
              participants.remove(_currentUser.uid);
              final String recipientId = participants.first;
              final Map<String, dynamic> user = {}; // Replace with actual user data

              return ListTile(
                title: Text('Chat with: $recipientId'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatPage(
                        chatRoomId: chatRoom.id,
                        recipientId: recipientId,
                        user: user, // Provide the required user parameter
                      ),
                    ),
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
