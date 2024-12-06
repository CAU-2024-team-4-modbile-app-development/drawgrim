import 'dart:math';
import 'dart:typed_data';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'drawing_board_module_test.dart';


class ViewerPage extends StatefulWidget {
  final String roomId;

  const ViewerPage({super.key, required this.roomId});

  @override
  State<ViewerPage> createState() => _ViewerPageState();
}

class _ViewerPageState extends State<ViewerPage> {
  final currentUser = FirebaseAuth.instance.currentUser;
  final _controller = TextEditingController();

  Stream<List<Map<String, dynamic>>> getPlayerInfo() {
    return FirebaseFirestore.instance
        .collection('gameRooms')
        .doc(widget.roomId)
        .collection('players')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              return {
                'username': doc.data()['username'] ?? 'Unknown',
              };
            }).toList());
  }

  Stream<Map<String, dynamic>> getPlayerRoles() {
    return FirebaseFirestore.instance
        .collection('gameRooms')
        .doc(widget.roomId)
        .collection('players')
        .snapshots()
        .map((snapshot) {
      Map<String, dynamic> roles = {
        'drawer': null, // 현재 그림을 그리는 사용자의 uid
        'viewer': [],   // 그림을 보고 있는 사용자의 uid 목록
      };
      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['isDrawer'] == true) {
          roles['drawer'] = doc.id; // uid는 문서 ID로 가정
        }
        if (data['isViewer'] == true) {
          roles['viewer'].add(doc.id); // uid를 추가
        }
      }
      return roles;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("정답입력: "),
            Expanded(
              child: NewMessage(roomId: widget.roomId),
            ),
          ],
        ),
      ),
      body: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: StreamBuilder<DatabaseEvent>(
                      stream: FirebaseDatabase.instance
                          .ref('images')
                          .orderByChild('timestamp')
                          .limitToLast(1)
                          .onValue,
                      builder: (context, snapshot) {
                        if (!snapshot.hasData ||
                            snapshot.data?.snapshot.value == null) {
                          return Center(child: CircularProgressIndicator());
                        }

                        final data = snapshot.data!.snapshot.value as Map;
                        List<MapEntry> sortedEntries = data.entries.toList()
                          ..sort((a, b) => b.value['timestamp']
                              .compareTo(a.value['timestamp']));

                        var lastEntry = sortedEntries.first;
                        String base64String = lastEntry.value['image_data'];

                        Uint8List imageData = base64Decode(base64String);

                        return AnimatedSwitcher(
                          duration: Duration(milliseconds: 200),
                          child: Image.memory(
                            imageData,
                            key: ValueKey<String>(lastEntry.key),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: getPlayerInfo(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Center(child: CircularProgressIndicator());
              }

              final players = snapshot.data!;
              List<Widget> faceIcons = [];

              for (int i = 0; i < players.length; i++) {
                final player = players[i];
                final alignment = i == 0
                    ? Alignment.topLeft
                    : i == 1
                        ? Alignment.topRight
                        : i == 2
                            ? Alignment.bottomLeft
                            : Alignment.bottomRight;

                faceIcons.add(
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Align(
                      alignment: alignment,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 둥근 아바타
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.blueAccent.withOpacity(0.7),
                            child: Icon(
                              Icons.face,
                              size: 50,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 10),
                          // 이름표
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  offset: Offset(0, 2),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: 6,
                              horizontal: 12,
                            ),
                            child: Text(
                              player['username'],
                              style: TextStyle(
                                fontSize: 25,
                                fontWeight: FontWeight.bold,
                                color: Colors.blueAccent,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              return Stack(
                children: [
                  // 사용자 아바타를 배치
                  ...faceIcons,
                ],
              );
            },
          ),
          StreamBuilder<Map<String, dynamic>>(
            stream: getPlayerRoles(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Center(child: CircularProgressIndicator());
              }

              final roles = snapshot.data!;
              final String? drawer = roles['drawer'];
              final List<dynamic> viewers = roles['viewer'];

              if (drawer == currentUser?.uid) {
                Future.microtask(() => Navigator.pushReplacement(
                    context,
                    MaterialPage  Route(
                      builder: (context) => DrawingPage(roomId: widget.roomId),
                    )));
              }
              return(
              SizedBox.shrink()
              );
            },
          ),
        ],
      ),
    );
  }
}

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
            final roomRef =
            FirebaseFirestore.instance.collection('gameRooms').doc(widget.roomId);
            final QuerySnapshot subjectSnapshot =
            await roomRef.collection('subject').get();

            final DocumentSnapshot doc = subjectSnapshot.docs.first;
            String answer = doc['answer'];

            if(newMessage == answer){

            }// 수정 필요
                _controler.clear();

                setState(() {
                  newMessage = '';
                });
          },
          icon: Icon(Icons.send),
        )
      ],
    );
  }
}