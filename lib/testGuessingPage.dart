import 'dart:math';
import 'dart:typed_data';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'drawing_board_module_test.dart';
import 'Ranking.dart';

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
        'userId': doc.id,
        'score': doc.data()['score'] ?? 0,
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
        'drawer': null,
        'viewer': [],
      };
      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['isDrawer'] == true) {
          roles['drawer'] = doc.id;
        }
        if (data['isViewer'] == true) {
          roles['viewer'].add(doc.id);
        }
      }
      return roles;
    });
  }

  void removePlayerFromGameRoom(String roomId) async {
    final authentication = FirebaseAuth.instance;
    try {
      final roomRef =
      FirebaseFirestore.instance.collection('gameRooms').doc(roomId);
      await roomRef.update({
        'players': FieldValue.arrayRemove([authentication.currentUser?.email]),
      });

      await roomRef
          .collection('players')
          .doc(authentication.currentUser?.email)
          .delete();
    } catch (e) {
      print("Error removing player from room: $e");
    }
  }

  void navigateToRankingPage() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Fetch top 3 players based on score
      final playerInfoSnapshot = await FirebaseFirestore.instance
          .collection('gameRooms')
          .doc(widget.roomId)
          .collection('players')
          .orderBy('score', descending: true)
          .limit(3)
          .get();

      // Collect player names
      List topPlayers = playerInfoSnapshot.docs
          .map((doc) => doc.data()['username'] ?? 'Unknown')
          .toList();

      // Navigate to Ranking page with top 3 player names
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => Ranking(
            roomId: widget.roomId,
            first: topPlayers.length > 0 ? topPlayers[0] : '없음',
            second: topPlayers.length > 1 ? topPlayers[1] : '없음',
            third: topPlayers.length > 2 ? topPlayers[2] : '없음',
          ),
        ),
      );
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Container(
          padding: const EdgeInsets.all(170.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("정답 입력: "),
              Expanded(
                child: NewMessage(roomId: widget.roomId),
              ),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          Row(
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
                              return Center(
                                  child: CircularProgressIndicator());
                            }

                            final data = snapshot.data!.snapshot.value as Map;
                            List<MapEntry> sortedEntries =
                            data.entries.toList()
                              ..sort((a, b) => b.value['timestamp']
                                  .compareTo(a.value['timestamp']));

                            var lastEntry = sortedEntries.first;
                            String base64String = lastEntry.value['image_data'];

                            Uint8List imageData =
                            base64Decode(base64String);

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
                  final sortedPlayers = List<Map<String, dynamic>>.from(players)
                    ..sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));

                  // Check if any player's score is 100 or more
                  bool isAnyPlayerScoreAboveThreshold = sortedPlayers
                      .any((player) => (player['score'] as int) >= 100);

                  if (isAnyPlayerScoreAboveThreshold) {
                    navigateToRankingPage();
                  }

                  return Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: sortedPlayers.map((player) {
                          int rank = sortedPlayers.indexOf(player) + 1;

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Card(
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Container(
                                width: 150,
                                padding: const EdgeInsets.all(12),
                                child: Stack(
                                  children: [
                                    if (rank <= 3)
                                      Positioned(
                                        left: 0,
                                        top: 0,
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: rank == 1
                                                ? Color(0xFFFFD700)
                                                : rank == 2
                                                ? Color(0xFFC0C0C0)
                                                : Colors.brown,
                                            borderRadius: BorderRadius.only(
                                              topLeft: Radius.circular(15),
                                              bottomRight: Radius.circular(15),
                                            ),
                                          ),
                                          child: Text(
                                            '$rank등',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    Column(
                                      children: [
                                        CircleAvatar(
                                          radius: 30,
                                          backgroundColor: Colors.blueAccent
                                              .withOpacity(0.7),
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
                                            color: Colors.blueAccent,
                                          ),
                                        ),
                                        SizedBox(height: 5),
                                        Row(
                                          mainAxisAlignment:
                                          MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.star,
                                              color: Colors.amber,
                                              size: 20,
                                            ),
                                            SizedBox(width: 5),
                                            Text(
                                              '점수: ${player['score']}',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          StreamBuilder<Map<String, dynamic>>(
            stream: getPlayerRoles(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Center(child: CircularProgressIndicator());
              }

              final roles = snapshot.data!;
              String? drawer = roles['drawer'];
              final List<dynamic> viewers = roles['viewer'];

              if (drawer == currentUser?.email) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DrawingPage(roomId: widget.roomId),
                    ),
                  );
                });
              }

              return SizedBox.shrink();
            },
          ),
          Positioned(
            bottom: 20,
            right: 30,
            child: FloatingActionButton.extended(
              onPressed: () {
                removePlayerFromGameRoom(widget.roomId);
                Navigator.of(context).pop();
              },
              label: Text(
                "나가기",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              icon: Icon(
                Icons.exit_to_app,
                color: Colors.white,
              ),
              backgroundColor: Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}

class NewMessage extends StatefulWidget {
  final String roomId;
  const NewMessage({super.key, required this.roomId});

  @override
  State<NewMessage> createState() => _NewMessageState();
}

class _NewMessageState extends State<NewMessage> {
  final _controler = TextEditingController();
  String newMessage = '';

  void _showPopup(String message, bool isCorrect) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: isCorrect ? Colors.green : Colors.red,
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: MediaQuery.of(context).size.width * 0.3,
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: TextField(
              controller: _controler,
              decoration: const InputDecoration(
                labelText: '답을 입력하세요',
              ),
              onChanged: (value) {
                setState(() {
                  newMessage = value;
                });
              },
            ),
          ),
        ),
        IconButton(
          color: Colors.deepOrange,
          onPressed: newMessage.trim().isEmpty
              ? null
              : () async {
            final roomRef = FirebaseFirestore.instance
                .collection('gameRooms')
                .doc(widget.roomId);
            final QuerySnapshot subjectSnapshot =
            await roomRef.collection('subject').get();

            final DocumentSnapshot doc = subjectSnapshot.docs.first;
            String answer = doc['answer'];

            if (newMessage.trim() == answer) {
              _showPopup('정답입니다!', true);

              final currentUser = FirebaseAuth.instance.currentUser;
              if (currentUser != null) {
                final playerRef = roomRef
                    .collection('players')
                    .doc(currentUser?.email);

                await FirebaseFirestore.instance
                    .runTransaction((transaction) async {
                  DocumentSnapshot playerSnapshot =
                  await transaction.get(playerRef);

                  if (playerSnapshot.exists) {
                    int currentScore = playerSnapshot.get('score') ?? 0;
                    transaction.update(playerRef, {
                      'score': currentScore + 50
                    });
                  }
                });
              }
            } else {
              _showPopup('오답입니다!', false);
            }

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
