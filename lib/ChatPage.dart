import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_chat_bubble/chat_bubble.dart';
import 'SelectOrder.dart';

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
    updatePresence(true);
  }

  // 현재 로그인한 사용자 정보 가져오기
  void getCurrentUser() {
    final user = _authentication.currentUser;
    if (user != null) {
      loggedUser = user;
    }
  }

  // 유저의 로그인 상태를 업데이트
  void updatePresence(bool isOnline) async {
    if (loggedUser != null) {
      final roomRef = FirebaseFirestore.instance.collection('gameRooms').doc(widget.roomId);

      // 플레이어가 방에 있는지 확인
      final roomSnapshot = await roomRef.get();

      if (!roomSnapshot.exists) {
        print("Room does not exist.");
        return;
      }

      final playersList = List<String>.from(roomSnapshot['players']); // 현재 플레이어 리스트

      if (isOnline) {
        if (!playersList.contains(_authentication.currentUser!.email)) {
          // 없으면 추가
          await roomRef.update({
            'players': FieldValue.arrayUnion([_authentication.currentUser!.email]),
          });
        }

        await roomRef.collection('players').doc(_authentication.currentUser!.email).set({
          'username': loggedUser!.displayName ?? 'Anonymous',
          'isOnline': true,
        });
      } else {
        // 오프라인이면 doc의 플레이어 리스트 항목에서 제거
        await roomRef.update({
          'players': FieldValue.arrayRemove([_authentication.currentUser!.email]),
        });

        await roomRef.collection('players').doc(_authentication.currentUser!.email).delete();
      }
    }
  }

// Firestore에서 현재 게임룸의 플레이어 수를 실시간으로 가져오는 함수
  Stream<int> getNumUsers() {
    return FirebaseFirestore.instance
        .collection('gameRooms')
        .doc(widget.roomId)
        .collection('players')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

// 유저 수를 표시하는 위젯
  Widget userCountWidget() {
    return StreamBuilder<int>(
      stream: getNumUsers(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Text('유저 수: 0');
        }
        return Text('유저 수: ${snapshot.data}');
      },
    );
  }

// 게임룸에서 플레이어 제거
  void removePlayerFromGameRoom(String roomId) async {
    try {
      final roomRef = FirebaseFirestore.instance.collection('gameRooms').doc(roomId);


      await roomRef.update({
        'players': FieldValue.arrayRemove([_authentication.currentUser?.email]),
      });


      await roomRef.collection('players').doc(_authentication.currentUser?.email).delete();
    } catch (e) {
      print("Error removing player from room: $e");
    }
  }

  @override
  void dispose() {
    updatePresence(false); // 플레이어 오프라인 전환
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop){  //채팅방에서 뒤로가기 누르면 게임룸에서 제거
          removePlayerFromGameRoom(widget.roomId);
          return;
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                      color: Colors.black,
                      width: 1.0
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ElevatedButton(
                  onPressed: (){
                    Navigator.push(context, MaterialPageRoute(
                        builder: (context) => Selectorder())
                    );


                  },
                  child: Text("게임 시작", style: TextStyle(fontSize: 20),),
                ),

              ),
              userCountWidget()

            ],
          ),


        ),

        body: StreamBuilder<int>(
          stream: getNumUsers(), // Listen to the stream
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              // Show loading while waiting for the data
              return Center(child: CircularProgressIndicator());
            }

            // Get the number of users
            int numUsers = snapshot.data!;

            // Create a list of widgets based on the number of users
            List<Widget> faceIcons = [];

            if (numUsers >= 1) {
              faceIcons.add(const Padding(
                padding: EdgeInsets.all(8.0),
                child: Align(alignment: Alignment.topLeft, child: Icon(Icons.face, size: 50)),
              ));
            }
            if (numUsers >= 2) {
              faceIcons.add(const Padding(
                padding: EdgeInsets.all(8.0),
                child: Align(alignment: Alignment.topRight, child: Icon(Icons.face, size: 50)),
              ));
            }
            if (numUsers >= 3) {
              faceIcons.add(const Padding(
                padding: EdgeInsets.all(8.0),
                child: Align(alignment: Alignment.bottomLeft, child: Icon(Icons.face_3, size: 50)),
              ));
            }
            if (numUsers >= 4) {
              faceIcons.add(const Padding(
                padding: EdgeInsets.all(8.0),
                child: Align(alignment: Alignment.bottomRight, child: Icon(Icons.face_4, size: 50)),
              ));
            }

            return Stack(
              children: [
                // Background content of your page
            Center(
            child: Stack(
            children: [
              // 채팅창 Container
              Align(
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Container(

                    decoration: BoxDecoration(
                      border: Border.all(
                          color: Colors.black,
                          width: 1.0
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),


                    width: 500,
                    height: 500,
                    child: Column(
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
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // 이모티콘들: 채팅방을 둘러싸도록 배치

            ],
            ),
            ),

                // Overlay face icons based on number of users
                ...faceIcons,
              ],
            );
          },
        ),
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
                // Text("GOOD!!!") 디버깅용 문장
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