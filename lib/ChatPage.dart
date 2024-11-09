import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_chat_bubble/chat_bubble.dart';



class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _authentication = FirebaseAuth.instance;
  User? loggedUser;

  @override
  void initState() {
    super.initState();
    getCurrentUser();
  }

  void getCurrentUser() {
    try {
      final user = _authentication.currentUser;
      if (user != null) {
        loggedUser = user;
      }
    } catch (e) {
      print(e);
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
          Expanded(
            child: StreamBuilder(stream: FirebaseFirestore.instance.collection('chat').orderBy('timestamp').snapshots(),
                builder: (context,snapshot){
              if(snapshot.connectionState == ConnectionState.waiting){
                return Center(child: CircularProgressIndicator());
              }
              final docs=snapshot.data!.docs;
              return ListView.builder(itemBuilder:(context,index){
                return ChatElement(
                  isMe:docs[index]['uid']==_authentication.currentUser!.uid ,
                  userName: docs[index]['userName'],
                  text: docs[index]['text'],
                );
              },itemCount: docs.length,);
                }
            ),
          ),
          NewMessage()
        ],
      )
    );
  }
}

class ChatElement extends StatelessWidget {
  const ChatElement({super.key,this.isMe,this.userName,this.text});
  final bool? isMe;
  final String? userName;
  final String? text;

  @override
  Widget build(BuildContext context) {
    if(isMe!){
      return   Padding(
        padding: const EdgeInsets.only(right:16.0),
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
                  userName!,
                  style: TextStyle(
                    color:  Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  text!,
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      );
  }
  else {
      return Padding(
        padding: const EdgeInsets.only(left: 16.0),
        child: ChatBubble(
          clipper: ChatBubbleClipper3(type: BubbleType.receiverBubble),
          backGroundColor: Color(0xffE7E7ED),
          margin: EdgeInsets.only(top: 20),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery
                  .of(context)
                  .size
                  .width * 0.7,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName!,
                  style: TextStyle(
                    color:  Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  text!,
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


class NewMessage extends StatefulWidget {
  const NewMessage({super.key});

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
            // Proceed only if the message is not empty
            final currentUser = FirebaseAuth.instance.currentUser;
            if (currentUser != null) {
              final currentUserInfo = await FirebaseFirestore.instance
                  .collection('user')
                  .doc(currentUser.uid)
                  .get();

              if (currentUserInfo.exists) {
                FirebaseFirestore.instance.collection('chat').add({
                  'text': newMessage,
                  'userName': currentUserInfo.data()!['userName'],
                  'timestamp': Timestamp.now(),
                  'uid': currentUser.uid,
                });
                _controler.clear();

                // Clear the input field after sending the message
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
