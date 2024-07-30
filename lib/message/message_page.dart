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

  Future<void> _deleteChatRoom(String chatRoomId) async {
    try {
      // Delete all messages in the chat room
      var messages = await FirebaseFirestore.instance
          .collection('chatRooms')
          .doc(chatRoomId)
          .collection('messages')
          .get();

      for (var message in messages.docs) {
        await FirebaseFirestore.instance
            .collection('chatRooms')
            .doc(chatRoomId)
            .collection('messages')
            .doc(message.id)
            .delete();
      }

      // Delete the chat room
      await FirebaseFirestore.instance.collection('chatRooms').doc(chatRoomId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Chat deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete chat')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.orange[500],
        title: const Text('Messages'),
      ),
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
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(recipientId).get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return SizedBox(
                      height: 80, // Placeholder height while loading
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return SizedBox.shrink(); // Skip if user data not found
                  }
                  Map<String, dynamic> user = snapshot.data!.data() as Map<String, dynamic>;
                  return _buildChatItem(user, chatRoom.id, recipientId);
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildChatItem(Map<String, dynamic> user, String chatRoomId, String recipientId) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        radius: 24,
        backgroundImage: NetworkImage(user['profileImageUrl'] ?? ''), // Replace with user profile image
      ),
      title: Text(
        user['name'] ?? 'Unknown',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        'Last message here...', // Implement logic to fetch and display last message
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '12:34 PM', // Replace with time logic
            style: TextStyle(color: Colors.grey),
          ),
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: () => _deleteChatRoom(chatRoomId),
          ),
        ],
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatPage(
              chatRoomId: chatRoomId,
              recipientId: recipientId,
              user: user,
            ),
          ),
        );
      },
    );
  }
}
