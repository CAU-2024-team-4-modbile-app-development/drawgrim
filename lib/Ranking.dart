import 'package:flutter/material.dart';
import 'package:rive/rive.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

class Ranking extends StatefulWidget {
  String? first;
  String? second;
  String? third;
  final String roomId;

  Ranking({
    super.key,
    required this.roomId,
    required this.first,
    required this.second,
    required this.third,
  });

  @override
  State<Ranking> createState() => _RankingState();
}

class _RankingState extends State<Ranking> {
  void _onRiveInit(Artboard artboard) async {
    final controller = StateMachineController.fromArtboard(
      artboard,
      'State Machine 1',
      // onStateChange: _onStateChange,
    );

    if (controller != null) {
      artboard.addController(controller);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Flexible(
            flex: 7,
            child: Stack(
              children: [
                Positioned.fill(
                  child: RiveAnimation.asset(
                    "assets/medal.riv",
                    fit: BoxFit.contain,
                    onInit: _onRiveInit,
                  ),
                ),
                Positioned(
                  top: 50,
                  left: 130,
                  child: Card(
                    color:  Color(0xFFC0C0C0),
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.white,
                            child: Icon(
                              Icons.person,
                              size: 70,
                              color: Color(0xFFC0C0C0),
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            widget.second ?? "",
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 50,
                  left: 370,
                  child: Card(
                    color:  Color(0xFFFFD700),
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.white,
                            child: Icon(
                              Icons.person,
                              size: 70,
                              color:  Color(0xFFFFD700),
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            widget.first ?? "",
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 50,
                  left: 600,
                  child: Card(
                    color: Colors.brown,
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.white,
                            child: Icon(
                              Icons.person,
                              size: 70,
                              color:Colors.brown,
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            widget.third ?? "",
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            flex: 1,
            child: Positioned(
              bottom: 100, // 조정하여 버튼을 위로 이동
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
          ),
        ],
      ),
    );
  }
}
