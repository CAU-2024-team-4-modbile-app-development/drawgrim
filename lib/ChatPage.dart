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
  bool isReady = false; // 준비 상태
  bool isHost = false; // 방장 여부

  @override
  void initState() {
    super.initState();
    getCurrentUser();
    updatePresence(true);
    checkIfHost();
  }

  // 현재 로그인한 사용자 정보 가져오기
  void getCurrentUser() {
    final user = _authentication.currentUser;
    if (user != null) {
      loggedUser = user;
    }
  }

  void checkIfHost() async {
    try {
      // Firebase Firestore의 roomId를 사용하여 해당 방의 정보를 가져옴
      final roomRef = FirebaseFirestore.instance.collection('gameRooms').doc(widget.roomId);

      final roomSnapshot = await roomRef.get();

      // 방이 존재하는지 확인
      if (roomSnapshot.exists) {
        // 방장이 누구인지 확인 (createdBy 필드)
        final createdBy = roomSnapshot['createdBy'];

        // 현재 사용자가 방장과 일치하는지 확인
        if (createdBy == _authentication.currentUser?.email) {
          // 현재 사용자가 방장이라면 Firestore에 사용자 상태 업데이트
          try {
            await roomRef.collection('players').doc(_authentication.currentUser!.email).set({
              'username': _authentication.currentUser?.email ?? 'Anonymous',
              'isOnline': true,
              'isReady': true,
              'isHost': true,
            });
            print('Player data successfully written to Firestore');
          } catch (e) {
            print('Error writing player data to Firestore: $e');
          }
          // UI 업데이트
          setState(() {
            isReady = true; // 준비 상태
            isHost = true;  // 방장 여부
          });
        }
      } else {
        print('error');
      }
    } catch (e) {
      // 오류가 발생했을 때 처리
      print('Error checking host: $e');
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
          'username': _authentication.currentUser!.email ?? 'Anonymous',
          'isOnline': true,
          'isReady': false, // 준비 상태 초기화
          'isHost':false,
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

  void toggleReady() async {
    setState(() {
      isReady = !isReady;
    });
    if (loggedUser != null) {
      final roomRef = FirebaseFirestore.instance.collection('gameRooms').doc(widget.roomId);
      await roomRef.collection('players').doc(loggedUser!.email).update({
        'isReady': isReady,
      });
    }
  }

// 게임 시작 함수 (방장만 가능)
  void startGame() async {
    if (isHost) {
      // 게임 시작 전 준비된 플레이어가 모두 있는지 확인
      final roomRef = FirebaseFirestore.instance.collection('gameRooms').doc(widget.roomId);
      final playersSnapshot = await roomRef.collection('players').get();
      bool allReady = true;
      for (var playerDoc in playersSnapshot.docs) {
        if (!playerDoc['isReady']) {
          allReady = false;
          break;
        }
      }

      if (allReady) {
        // 게임 시작 상태를 Firestore에 저장
        await roomRef.update({
          'gameStarted': true,
        });

        // 게임 시작
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => Selectorder()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('모든 플레이어가 준비되어야 게임을 시작할 수 있습니다.')),
        );
      }
    }
  }

  // Firestore에서 게임 시작 상태를 실시간으로 감지
  Stream<DocumentSnapshot> getGameStartedStatus() {
    return FirebaseFirestore.instance
        .collection('gameRooms')
        .doc(widget.roomId)
        .snapshots();
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
    return WillPopScope(
      onWillPop: () async {
        removePlayerFromGameRoom(widget.roomId);
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // 게임 시작 버튼 (방장만 클릭 가능)
              if (isHost)
                ElevatedButton(
                  onPressed: startGame,
                  child: Text("게임 시작", style: TextStyle(fontSize: 20)),
                ),
              // 준비 상태 버튼
              if(!isHost)
                ElevatedButton(
                  onPressed: toggleReady,
                  child: Text(isReady ? "준비 완료" : "준비하기"),
                ),
            ],
          ),
        ),
        body: StreamBuilder<DocumentSnapshot>(
          stream: getGameStartedStatus(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final roomData = snapshot.data?.data() as Map<String, dynamic>?;
            if (roomData != null && roomData['gameStarted'] == true) {
              // 게임이 시작되었으면 Selectorder 페이지로 이동
              Future.delayed(Duration.zero, () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => Selectorder()),
                );
              });
            }

            return StreamBuilder<int>(
              stream: getNumUsers(),
              builder: (context, userSnapshot) {
                if (!userSnapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                int numUsers = userSnapshot.data!;
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
                        ],
                      ),
                    ),
                    // Overlay face icons based on number of users
                    ...faceIcons,
                  ],
                );
              },
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