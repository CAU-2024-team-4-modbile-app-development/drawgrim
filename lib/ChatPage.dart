import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_chat_bubble/chat_bubble.dart';

class ChatPage extends StatefulWidget {
  final String roomId; // 채팅방 ID

  const ChatPage({super.key, required this.roomId});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _authentication = FirebaseAuth.instance;
  User? loggedUser;
  final _messageController = TextEditingController();
  String newMessage = '';

  @override
  void initState() {
    super.initState();
    getCurrentUser();
  }

  // 현재 로그인한 사용자 정보 가져오기
  void getCurrentUser() {
    final user = _authentication.currentUser;
    if (user != null) {
      loggedUser = user;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
        actions: [
          IconButton(
              onPressed: () {
                FirebaseAuth.instance.signOut();
              },
              icon: Icon(Icons.logout))
        ],
      ),
      body: Column(
        children: [
          // 채팅 메시지 스트림
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('gameRooms')
                  .doc(widget.roomId)
                  .collection('messages')
                  .orderBy('timestamp')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    return ChatElement(
                      isMe: docs[index]['uid'] == _authentication.currentUser!.uid,
                      userName: docs[index]['userName'],
                      text: docs[index]['text'],
                    );
                  },
                );
              },
            ),
          ),
          // 메시지 입력 필드
          NewMessage(
            onSendMessage: sendMessage,
            messageController: _messageController,
            newMessage: newMessage,
            onChanged: (value) {
              setState(() {
                newMessage = value;
              });
            },
          )
        ],
      ),
    );
  }

  // Firestore에 메시지를 추가하는 함수
  Future<void> sendMessage() async {
    if (newMessage.trim().isEmpty) return;

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final currentUserInfo = await FirebaseFirestore.instance
            .collection('user')
            .doc(currentUser.uid)
            .get();

        if (currentUserInfo.exists) {
          await FirebaseFirestore.instance.collection('gameRooms')
              .doc(widget.roomId)
              .collection('messages')
              .add({
            'text': newMessage,
            'userName': currentUserInfo.data()!['userName'],
            'timestamp': Timestamp.now(),
            'uid': currentUser.uid,
          });

          // 입력 필드 초기화
          setState(() {
            newMessage = '';
            _messageController.clear();
          });
        }
      }
    } catch (e) {
      print("Error sending message: $e");
    }
  }
}

// 채팅 메시지를 표시하는 위젯
class ChatElement extends StatelessWidget {
  final bool isMe;
  final String userName;
  final String text;

  const ChatElement({
    super.key,
    required this.isMe,
    required this.userName,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    if (isMe) {
      return Padding(
        padding: const EdgeInsets.only(right: 16.0),
        child: ChatBubble(
          clipper: ChatBubbleClipper3(type: BubbleType.sendBubble),
          alignment: Alignment.topRight,
          margin: EdgeInsets.only(top: 20),
          backGroundColor: Colors.deepPurple,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  userName,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  text,
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.only(left: 16.0),
        child: ChatBubble(
          clipper: ChatBubbleClipper3(type: BubbleType.receiverBubble),
          backGroundColor: Color(0xffE7E7ED),
          margin: EdgeInsets.only(top: 20),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  text,
                  style: TextStyle(color: Colors.black),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }
}

// 메시지 입력 위젯
class NewMessage extends StatelessWidget {
  final String newMessage;
  final TextEditingController messageController;
  final ValueChanged<String> onChanged;
  final Function onSendMessage;

  const NewMessage({
    super.key,
    required this.newMessage,
    required this.messageController,
    required this.onChanged,
    required this.onSendMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: messageController,
              decoration: const InputDecoration(
                labelText: 'New Message',
              ),
              onChanged: onChanged,
            ),
          ),
        ),
        IconButton(
          color: Colors.deepOrange,
          onPressed: newMessage.trim().isEmpty ? null : () => onSendMessage(),
          icon: Icon(Icons.send),
        ),
      ],
    );
  }
}