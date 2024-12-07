import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drawgrim/DecideSubject.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'NewMessage.dart';
import 'ChatElement.dart';
import 'Words.dart';

class ChatPage extends StatefulWidget {
  final String roomId; // 채팅방 ID

  const ChatPage({super.key, required this.roomId});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {

  final _authentication = FirebaseAuth.instance;
  final ScrollController _scrollController = ScrollController(); // ScrollController 추가
  bool _isNearBottom = true; // 사용자가 하단 근처에 있는지 추적

  User? loggedUser;
  String newMessage = '';

  bool isReady = false; // 준비 상태
  bool isHost = false; // 방장 여부

  @override
  void initState() {
    super.initState();
    getCurrentUser();
    checkIfHost();
  }

  // 현재 로그인한 사용자 정보 가져오기
  void getCurrentUser() {
    final user = _authentication.currentUser;
    if (user != null) {
      loggedUser = user;
    }
  }

  Future<void> checkIfHost() async {
    try {
      // Firebase Firestore의 roomId를 사용하여 해당 방의 정보를 가져옴
      final roomRef =
      await FirebaseFirestore.instance.collection('gameRooms').doc(
          widget.roomId);

      final roomSnapshot = await roomRef.get();

      // 방이 존재하는지 확인
      if (roomSnapshot.exists) {
        // 방장이 누구인지 확인 (createdBy 필드)
        final createdBy = roomSnapshot['createdBy'];

        // 현재 사용자가 방장과 일치하는지 확인
        if (createdBy == _authentication.currentUser?.email) {
          setState(() {
            isReady = true; // 준비 상태
            isHost = true; // 방장 여부
          });
        }
      } else {
        print('error');
      }
    } catch (e) {
      // 오류가 발생했을 때 처리
      print('Error checking host: $e');
    }

    await updatePresence(true);
  }



  // 유저의 로그인 상태를 업데이트
  Future<void> updatePresence(bool isOnline) async {
    final roomRef =
    await FirebaseFirestore.instance.collection('gameRooms').doc(widget.roomId);

    final roomSnapshot = await roomRef.get();
    final currentUser = FirebaseAuth.instance.currentUser;

    final currentUserInfo = await FirebaseFirestore.instance
        .collection('user')
        .doc(currentUser!.uid)
        .get();
    if (loggedUser != null) {
      if (!roomSnapshot.exists) {
        print("Room does not exist.");
        return;
      }

      final playersList =
      List<String>.from(roomSnapshot['players']); // 현재 플레이어 리스트

      if (isOnline) {
        if (!playersList.contains(_authentication.currentUser!.email)) {
          // 없으면 추가
          await roomRef.update({
            'players':
            FieldValue.arrayUnion([_authentication.currentUser!.email]),
          });
        }

        if (isHost == true) {
          await roomRef
              .collection('players')
              .doc(_authentication.currentUser!.email)
              .set({
            'username': currentUserInfo.data()!['userName'] ?? 'Anonymous',
            'isOnline': true,
            'isReady': true, // 준비 상태 초기화ddss
            'isHost': true,
          });
          await updateSubject();
        } else {
          await roomRef
              .collection('players')
              .doc(_authentication.currentUser!.email)
              .set({
            'username':currentUserInfo.data()!['userName'] ?? 'Anonymous',
            'isOnline': true,
            'isReady': false, // 준비 상태 초기화
            'isHost': false,
          });
        }
      } else {
        // 오프라인이면 doc의 플레이어 리스트 항목에서 제거
        // await roomRef.update({
        //   'players':
        //       FieldValue.arrayRemove([_authentication.currentUser!.email]),
        // });
        //
        // await roomRef
        //     .collection('players')
        //     .doc(_authentication.currentUser!.email)
        //     .delete();
      }
    }
  }

  Future<void> updateSubject() async {
    Words words = Words();
    String subject = '';

    final random = Random();
    int randomIndex = random.nextInt(3);

    switch (randomIndex) {
      case 0:
        setState(() {
          subject = "food";
        });

        break;
      case 1:
        setState(() {
          subject = "animal";
        });

        break;
      case 2:
        setState(() {
          subject = "plant";
        });

        break;
    }

    await FirebaseFirestore.instance
        .collection('gameRooms')
        .doc(widget.roomId)
        .collection('subject')
        .add({
      'subject': subject,
      'elements': words.returnSubjectList(subject),
      'answer': '',
    });

    // final roomRef =
    // FirebaseFirestore.instance.collection('gameRooms').doc(widget.roomId);
    // final QuerySnapshot subjectSnapshot =
    // await roomRef.collection('subject').get();
    //
    // final DocumentSnapshot doc = subjectSnapshot.docs.first;
    // final elements = doc['elements'];
    //
    // randomIndex = random.nextInt(elements.length);
    // final String selectedElement = elements[randomIndex];
    // print(selectedElement);
    //
    // elements.removeAt(randomIndex);
    //
    // await roomRef.collection('subject').doc(doc.id).update({
    //   'elements': elements,
    //   'answer': selectedElement,
    // });







  }

  Stream<List<Map<String, dynamic>>> getPlayerInfo() {
    return FirebaseFirestore.instance
        .collection('gameRooms')
        .doc(widget.roomId)
        .collection('players')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
      return {
        'username': doc.data()['username'] ?? 'Unknown',
        'isReady': doc.data()['isReady'] ?? false,
      };
    }).toList());
  }

  void toggleReady() async {
    setState(() {
      isReady = !isReady;
      print("Ready State: $isReady");
    });

    if (loggedUser != null) {
      print("LOGGEDUSER METHOD");
      try {
        final roomRef = FirebaseFirestore.instance
            .collection('gameRooms')
            .doc(widget.roomId);
        await roomRef.collection('players').doc(loggedUser!.email).update({
          'isReady': isReady,
        });
        print(roomRef.collection('players').doc(loggedUser!.email));
        //player 정보 확인용

        final playerDoc =
        await roomRef.collection('players').doc(loggedUser!.email).get();
        print("isReady 상태: ${playerDoc.data()?['isReady']}");
        //Ready상태 확인용

        print("Player's ready state updated successfully!");
      } catch (e) {
        print("ERROR: $e");
      }
    }
  }

// 게임 시작 함수 (방장만 가능)
  void startGame() async {
    print("START GAME PRESSED");

    if (isHost) {
      // 게임 시작 전 준비된 플레이어가 모두 있는지 확인
      final roomRef =
      FirebaseFirestore.instance.collection('gameRooms').doc(widget.roomId);
      final playersSnapshot = await roomRef.collection('players').get();
      bool allReady = true;

      print("업데이트중");

      List<String> emails = playersSnapshot.docs.map((doc) => doc.id).toList();
      //현재 게임 방에 있는 이메일 목록 리스트
      print("Player Emails: $emails");

      for (var playerDoc in playersSnapshot.docs) {
        print("isReady 상태: ${playerDoc.data()['isReady']}");
        print("이메일: ${playerDoc.data()['email']}");
        //디버깅용 문장

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
        // Navigator.push(
        //   context,
        //   MaterialPageRoute(
        //     builder: (context) => DecideSubject(roomId: widget.roomId),
        //   ),
        // );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('모든 플레이어가 준비되어야 게임을 시작할 수 있습니다.')),
        );
      }
      print("ALL READY STATE: $allReady");
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
      final roomRef =
      FirebaseFirestore.instance.collection('gameRooms').doc(roomId);

      await roomRef.update({
        'players': FieldValue.arrayRemove([_authentication.currentUser?.email]),
      });

      await roomRef
          .collection('players')
          .doc(_authentication.currentUser?.email)
          .delete();
    } catch (e) {
      print("Error removing player from room: $e");
    }
  }

  @override
  void dispose() {
    updatePresence(false); // 플레이어 오프라인 전환
    _scrollController.dispose();
    super.dispose();
  }
  void _scrollListener() {
    // 사용자가 하단 근처에 있는지 확인
    if (_scrollController.offset >=
        _scrollController.position.maxScrollExtent - 50 &&
        !_scrollController.position.outOfRange) {
      setState(() {
        _isNearBottom = true;
      });
    } else {
      setState(() {
        _isNearBottom = false;
      });
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients && _isNearBottom) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
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
          automaticallyImplyLeading: false, // 뒤로가기 버튼 제거
          title: Row(
            children: [
              // 나가기 버튼 (왼쪽 배치)
              Padding(
                padding: const EdgeInsets.only(left: 8.0,right:220), // 왼쪽에 간격 추가
                child: FloatingActionButton.extended(
                  onPressed: () {
                    removePlayerFromGameRoom(widget.roomId);
                    Navigator.of(context).pop();
                  },
                  label:Text(
                    "나가기",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),

                  icon: Icon(Icons.exit_to_app,
                    color: Colors.white,
                  ),
                  backgroundColor: Colors.red,
                ),
              ),

              if (isHost)
                Padding(
                  padding: const EdgeInsets.only(right: 8.0), // 오른쪽에 간격 추가
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade600, Colors.blue.shade800],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.shade200,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: startGame,
                      icon: Icon(
                        Icons.play_arrow,
                        size: 24,
                        color: Colors.white,
                      ),
                      label: Text(
                        "게임 시작",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                    ),
                  ),
                ),

              // 준비 버튼 (비방장일 경우만, 오른쪽 배치)
              if (!isHost)
                Padding(
                  padding: const EdgeInsets.only(right: 8.0), // 오른쪽에 간격 추가
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    decoration: BoxDecoration(

                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        colors: isReady
                            ? [Colors.green.shade100, Colors.green.shade200]
                            : [Colors.white, Colors.blue.shade50],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: OutlinedButton.icon(
                      onPressed: toggleReady,
                      icon: Icon(
                        isReady ? Icons.check_circle : Icons.timelapse,
                        size: 24,
                        color: isReady ? Colors.green : Colors.blueAccent,
                      ),
                      label: Text(
                        isReady ? "준비 완료" : "준비 하기",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: isReady ? Colors.green : Colors.blueAccent,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        side: BorderSide.none,
                        shadowColor: Colors.transparent,
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                    ),
                  ),
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
              Future.delayed(Duration.zero, () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) =>
                      DecideSubject(roomId: widget.roomId,)),
                );
              });
            }
            return StreamBuilder<List<Map<String, dynamic>>>(
              stream: getPlayerInfo(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                final players = snapshot.data!;
                List<Widget> playerIcons = [];

                for (int i = 0; i < players.length; i++) {
                  final player = players[i];
                  final alignment = i == 0
                      ? Alignment.topLeft
                      : i == 1
                      ? Alignment.topRight
                      : i == 2
                      ? Alignment.bottomLeft
                      : Alignment.bottomRight;

                  playerIcons.add(
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Align(
                        alignment: alignment,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.blueAccent.withOpacity(0.7),
                                Colors.blue.shade300.withOpacity(0.5)
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          width: 180,
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                radius: 40,
                                backgroundColor: Colors.white.withOpacity(0.2),
                                child: Icon(
                                  Icons.person,
                                  size: 50,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 10),
                              Text(
                                player['username'],
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      blurRadius: 10.0,
                                      color: Colors.black45,
                                      offset: Offset(2.0, 2.0),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }

                return Stack(
                  children: [
                    // Background with subtle pattern

                    // 채팅창 중심 컨테이너
                    Center(
                      child: Container(
                        width: 400,
                        height:400,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              offset: Offset(0, 4),
                              blurRadius: 15,
                            ),
                          ],
                          border: Border.all(
                            color: Colors.blueAccent.withOpacity(0.2),
                            width: 2,
                          ),
                        ),
                        child: Column(
                          children: [
                            // 채팅 메시지 스트림
                            Expanded(
                              child: StreamBuilder(
                                stream: FirebaseFirestore.instance
                                    .collection('gameRooms')
                                    .doc(widget.roomId)
                                    .collection('chat')
                                    .orderBy('timestamp')
                                    .snapshots(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return Center(child: CircularProgressIndicator());
                                  }
                                  final docs = snapshot.data!.docs;

                                  WidgetsBinding.instance.addPostFrameCallback((_) {
                                    _scrollToBottom();
                                  });

                                  return ListView.builder(
                                    controller: _scrollController,
                                    itemBuilder: (context, index) {
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16.0,
                                            vertical: 8.0
                                        ),
                                        child: ChatElement(
                                          isMe: docs[index]['uid'] ==
                                              _authentication.currentUser!.uid,
                                          userName: docs[index]['userName'],
                                          text: docs[index]['text'],
                                        ),
                                      );
                                    },
                                    itemCount: docs.length,
                                  );
                                },
                              ),
                            ),
                            // 메시지 입력 필드
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: NewMessage(roomId: widget.roomId),
                            ),

                          ],
                        ),
                      ),
                    ),
                    // 사용자 아바타를 배치
                    ...playerIcons,
                  ],

                );

              },
            );
          },
        ),


      ),
    );
  }
  }