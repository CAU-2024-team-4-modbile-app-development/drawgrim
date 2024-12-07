import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:drawgrim/ChatPage.dart'; // 채팅 페이지
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';

class GameRoom extends StatefulWidget {
  const GameRoom({super.key});

  @override
  _GameRoomState createState() => _GameRoomState();
}

class _GameRoomState extends State<GameRoom> {
  final _firestore = FirebaseFirestore.instance;
  final _authentication = FirebaseAuth.instance;
  bool loading = false;

  String roomName = '';
  final TextEditingController _roomNameController = TextEditingController();

  // 로그아웃 메서드
  void logOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pop(context);
    } catch (e) {
      print("Error logging out: $e");
    }
  }

// 방을 생성하는 메서드
  void createRoom() async {
    if (roomName.isNotEmpty) {
      setState(() {
        loading = true;
      });

      try {
        // Firebase Firestore에 방 생성
        var docRef = await _firestore.collection('gameRooms').add({
          'roomName': roomName,
          'createdBy': _authentication.currentUser?.email,
          'createdAt': Timestamp.now(),
          'players': [
            _authentication.currentUser?.email, // 방 생성자 추가
          ],
        });

        // 방이 생성되면 생성자의 이메일을 players 목록에 추가
        await docRef.update({
          'players': FieldValue.arrayUnion([_authentication.currentUser?.email]),
        });

        // 방 이름 초기화
        _roomNameController.clear();
        roomName = '';

        // 이후 방에 참가하도록 변경할 수도 있습니다. (선택사항)
        joinRoom(docRef.id);

      } catch (e) {
        print("Error creating room: $e");
      } finally {
        setState(() {
          loading = false;
        });
      }
    } else {
      // 방 이름이 비어있을 경우
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('방 이름 입력')),
      );
    }
  }

  // 방에 참가하는 메서드
  void joinRoom(String roomId) async {
    setState(() {
      loading = true;
    });

    try {
      // Firestore에서 해당 방에 현재 사용자 이메일을 추가
      await _firestore.collection('gameRooms').doc(roomId).update({
        'players': FieldValue.arrayUnion([_authentication.currentUser?.email]),
      });

      // 채팅 페이지로 이동
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatPage(roomId: roomId),
        ),
      );
    } catch (e) {
      print("Error joining room: $e");
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  // 유저 수가 0인 방 삭제 메서드
  void deleteEmptyRoom(String roomId) async {
    try {
      // Firestore에서 해당 방을 조회
      var roomSnapshot = await _firestore.collection('gameRooms').doc(roomId).get();
      if (roomSnapshot.exists) {
        List<dynamic> players = roomSnapshot['players'] ?? [];
        if (players.isEmpty) {
          // 유저가 없으면 해당 방을 삭제
          await _firestore.collection('gameRooms').doc(roomId).delete();
        }
      }
    } catch (e) {
      print("Error deleting empty room: $e");
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ModalProgressHUD(
        inAsyncCall: loading,
        child: Stack(
          children: [
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 10.0),
                          child: Center(
                            child: Text(
                              '방 목록',
                              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        SizedBox(height: 3),
                        // 방 목록을 표시하는 ListView (Firestore 스트림 구독)
                        Expanded(
                          child: StreamBuilder<QuerySnapshot>(
                            stream: _firestore
                                .collection('gameRooms')
                                .orderBy('createdAt', descending: true)
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return Center(child: CircularProgressIndicator());
                              }

                              final rooms = snapshot.data!.docs;

                              // 각 방을 순차적으로 확인하여 유저 수가 0인 방은 삭제
                              for (var room in rooms) {
                                List<dynamic> players = room['players'] ?? [];
                                if (players.isEmpty) {
                                  deleteEmptyRoom(room.id);
                                }
                              }

                              return ListView.builder(
                                itemCount: rooms.length,
                                itemBuilder: (context, index) {
                                  var room = rooms[index];
                                  List<dynamic> players = room['players'] ?? [];
                                  int playerCount = players.length;

                                  return Card(
                                    margin: EdgeInsets.symmetric(vertical: 8.0),
                                    elevation: 4.0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10.0),
                                    ),
                                    child: Container(
                                      height: 100,
                                      child: ListTile(
                                        contentPadding:
                                        EdgeInsets.symmetric(vertical: 3.0, horizontal: 16.0),
                                        title: Text(
                                          room['roomName'],
                                          style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
                                        ),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text('$playerCount/4', style: TextStyle(fontSize: 30)),
                                            SizedBox(width: 8),
                                            Icon(Icons.person, size: 30),
                                          ],
                                        ),
                                        onTap: () {
                                          joinRoom(room.id);
                                        },
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 190,
                          height: 190,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 10,
                                offset: Offset(0, 5),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.asset(
                              'assets/background.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Container(
                          margin: EdgeInsets.symmetric(vertical: 20.0),
                          child: TextField(
                            controller: _roomNameController,
                            decoration: const InputDecoration(
                              labelText: '방 이름 입력',
                              border: OutlineInputBorder(),
                            ),
                            style: TextStyle(
                              fontSize: 25.0, // 폰트 크기 설정
                              fontWeight: FontWeight.bold, // 굵게 설정
                              color: Colors.black, // 폰트 색상
                            ),

                            onChanged: (value) {
                              setState(() {
                                roomName = value;
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: createRoom,
                          child: const Text(
                            "방만들기",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            shadowColor: Colors.transparent,
                            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.logout, size: 30, color: Colors.red),
                onPressed: logOut,
              ),
            ),
          ],
        ),
      ),
    );
  }
}