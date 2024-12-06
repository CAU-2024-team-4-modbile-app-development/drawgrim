import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NewMessage extends StatefulWidget {
  final String roomId; // 채팅방 ID
  const NewMessage({super.key, required this.roomId});

  @override
  State<NewMessage> createState() => _NewMessageState();
}

class _NewMessageState extends State<NewMessage> {
  final _controler = TextEditingController();
  String newMessage = '';
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _controler,
                decoration: const InputDecoration(
                  labelText: 'New Message',
                ),
                onChanged: (value) {
                  setState(() {
                    newMessage = value;
                  });
                },
              ),
            )),
        IconButton(
          color: Colors.deepOrange,
          onPressed: newMessage.trim().isEmpty
              ? null
              : () async {
            final currentUser = FirebaseAuth.instance.currentUser;
            if (currentUser != null) {
              final currentUserInfo = await FirebaseFirestore.instance
                  .collection('user')
                  .doc(currentUser.uid)
                  .get();

              if (currentUserInfo.exists) {
                FirebaseFirestore.instance
                    .collection('gameRooms')
                    .doc(widget.roomId) // roomId 기반 저장
                    .collection('chat')
                    .add({
                  'text': newMessage,
                  'userName': currentUserInfo.data()!['userName'],
                  'timestamp': Timestamp.now(),
                  'uid': currentUser.uid,
                });
//dd
                _controler.clear();

                setState(() {
                  newMessage = '';
                });
              }
            }
          },
          icon: Icon(Icons.send),
        )
      ],
    );
  }
}