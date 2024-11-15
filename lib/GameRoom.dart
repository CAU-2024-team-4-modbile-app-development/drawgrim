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

  // 방 이름을 저장할 변수
  String roomName = '';
  // 텍스트 입력 컨트롤러
  final TextEditingController _roomNameController = TextEditingController();

  // 방 목록을 저장할 리스트
  List<DocumentSnapshot> rooms = [];

  // 방 목록을 불러오는 메서드
  void getRooms() async {
    setState(() {
      loading = true;
    });

    try {
      // Firebase Firestore에서 방 목록을 가져옴
      QuerySnapshot querySnapshot = await _firestore
          .collection('gameRooms')
          .orderBy('createdAt', descending: true)
          .get();

      setState(() {
        rooms = querySnapshot.docs;
        loading = false;
      });
    } catch (e) {
      print("Error fetching rooms: $e");
      setState(() {
        loading = false;
      });
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
        await _firestore.collection('gameRooms').add({
          'roomName': roomName,
          'createdBy': _authentication.currentUser?.email,
          'createdAt': Timestamp.now(),
          'players': [ // 방에 참여할 플레이어 리스트 초기화
            _authentication.currentUser?.email,
          ],
        });

        // 방 생성 후 방 목록을 새로 불러옴
        getRooms();
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
        SnackBar(content: Text('Please enter a room name')),
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
          builder: (context) => ChatPage(roomId: roomId), // 방 ID를 넘겨줌
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

  void logOut() async {
    try {

      await FirebaseAuth.instance.signOut();

      Navigator.pop(context);
    } catch (e) {
      print("Error logging out: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    getRooms();
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
                // 왼쪽에 방 목록을 표시할 영역
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 10.0),
                          child: Center(
                            child: Text(
                              '방 목록',
                              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        SizedBox(height: 3),
                        // 방 목록을 표시하는 ListView
                        Expanded(
                          child: ListView.builder(
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
                                child: ListTile(
                                  contentPadding: EdgeInsets.symmetric(vertical: 3.0, horizontal: 16.0),
                                  title: Text(
                                    room['roomName'],
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('$playerCount/5', style: TextStyle(fontSize: 16)),
                                    SizedBox(width: 8),
                                    Icon(Icons.person, size: 20),
                                  ],
                                ),
                                  onTap: () {
                                    // 방에 참가하는 로직
                                    joinRoom(room.id);
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // 오른쪽에 방 만들기와 방 조회 버튼
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 방 이름 입력
                        TextField(
                          controller: _roomNameController,
                          decoration: InputDecoration(
                            labelText: 'Enter Room Name',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) {
                            setState(() {
                              roomName = value;
                            });
                          },
                        ),
                        SizedBox(height: 20),
                        // 방 만들기 버튼
                        ElevatedButton(
                          onPressed: createRoom,
                          child: Text('Create Room'),
                        ),
                        SizedBox(height: 20),
                        // 방 조회 버튼
                        ElevatedButton(
                          onPressed: getRooms,
                          child: Text('Refresh Rooms'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // 오른쪽 상단에 로그아웃 버튼 추가
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                icon: Icon(Icons.logout, size: 30, color: Colors.red),
                onPressed: logOut,  // 로그아웃 후 이전 화면으로 돌아가기
              ),
            ),
          ],
        ),
      ),
    );
  }
}