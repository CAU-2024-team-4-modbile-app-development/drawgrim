import 'dart:math';

import 'package:drawgrim/testGuessingPage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:new_drawing_board_package/new_drawing_board.dart';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_database/firebase_database.dart';
import 'dart:convert'; //데이터 base64로 변환

import 'dart:async';

String promptWord = '';
Timer? _timer;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Drawing Test',
      theme: ThemeData(primarySwatch: Colors.blue),
      // home: const DrawingPage(roomId: "1234",),
    );
  }
}

class DrawingPage extends StatefulWidget {
  final String roomId;

  const DrawingPage({super.key, required this.roomId});

  @override
  State<DrawingPage> createState() => _DrawingPageState();
}

class _DrawingPageState extends State<DrawingPage>
    with SingleTickerProviderStateMixin {
  final DrawingController _drawingController = DrawingController();

  late AnimationController _timerController;
  final TransformationController _transformationController =
      TransformationController();
  Color timeColor = Colors.green;
  final double first_timeWidth = 300.0;
  double timeWidth = 300.0;
  bool isTimeLow = false;

  double _colorOpacity = 1;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> getAnswer_andUpdateElements() async {
    final roomRef =
        FirebaseFirestore.instance.collection('gameRooms').doc(widget.roomId);
    final QuerySnapshot subjectSnapshot =
        await roomRef.collection('subject').get();

    final DocumentSnapshot doc = subjectSnapshot.docs.first;
    List<dynamic> elements = doc['elements'];

    final random = Random();
    final randomIndex = random.nextInt(elements.length);
    final String selectedElement = elements[randomIndex];
    print("SELECTED: $selectedElement");

    elements.removeAt(randomIndex);

    await roomRef.collection('subject').doc(doc.id).update({
      'elements': elements,
      'answer': selectedElement,
    });

    setState(() {
      promptWord = selectedElement;
    });
  }

  void initState() {
    super.initState();
    getAnswer_andUpdateElements();
    _timerController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 10), // Set the desired countdown time
    )
      ..addListener(() {
        setState(() {
          // Update time bar color and width based on remaining time
          double progress = _timerController.value;
          timeColor = Color.lerp(Colors.green, Colors.red, progress)!;
          timeWidth = 300 * (1 - progress);

          // Trigger shake effect when time is low
          if (progress > 0.8) {
            isTimeLow = true;
          }
        });
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          // The timer has finished
          _onTimerComplete();
        }
      });

    // Start the timer when the game starts
    _timerController.forward();

    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (mounted && context != null) {
        _getImageData();
      } else {
        timer.cancel();
      }
    });
    //upload image every 1 second
  }

  /// Called when the timer finishes
  void _onTimerComplete() async {
    _timer!.cancel(); // Timer 중지
    _timer = null; // Timer 객체 제거

    final currentUser = FirebaseAuth.instance.currentUser;

    final CollectionReference playersRef = FirebaseFirestore.instance
        .collection('gameRooms')
        .doc(widget.roomId)
        .collection('players');

    final QuerySnapshot querySnapshot =
        await playersRef.orderBy(FieldPath.documentId).get();

    print("CURRENTUSER: ${currentUser?.email}");

    await playersRef.doc(currentUser?.email).update({
      'isDrawer': false,
      'isViewer': true,
    });

    for (var doc in querySnapshot.docs) {
      print("USER ID: ${doc.id}");
      final data = doc.data() as Map<String, dynamic>;
      if (doc.id == currentUser?.email) {
      } else {
        await playersRef.doc(doc.id).update({
          'isDrawer': true,
          'isViewer': false,
        });
        break;
      }
    }
    Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => ViewerPage(roomId: widget.roomId)));
  }

  @override
  void dispose() {
    // 모든 컨트롤러와 타이머 안전하게 해제
    _timerController.dispose();
    _drawingController.dispose();
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }

  Future<void> _uploadImage(Uint8List imageData) async {
    String base64String = base64Encode(imageData);

    DatabaseReference databaseRef = FirebaseDatabase.instance.ref('images');
    DatabaseReference newImageRef = databaseRef.push();

    // upload new image
    await newImageRef.set({
      'image_data': base64String,
      'timestamp': ServerValue.timestamp,
    });

    // organize data: maintain last 10 images
    DatabaseEvent event = await databaseRef.orderByChild('timestamp').once();
    DataSnapshot snapshot = event.snapshot;

    Map<dynamic, dynamic>? images = snapshot.value as Map?;

    if (images != null && images.length > 5) {
      // 오래된 데이터 삭제
      var sortedKeys = images.keys.toList()
        ..sort(
            (a, b) => images[a]['timestamp'].compareTo(images[b]['timestamp']));

      for (int i = 0; i < images.length - 5; i++) {
        await databaseRef.child(sortedKeys[i]).remove();
      }
    }

    print("Uploaded Image and cleaned up old entries.");
  }

  /// Capture the drawing data as image and upload
  Future<void> _getImageData() async {
    try {
      // null 체크와 함께 안전하게 이미지 데이터 가져오기
      final imageData = await _drawingController.getImageData();
      if (imageData != null) {
        final Uint8List data = imageData.buffer.asUint8List();
        await _uploadImage(data);
      }
    } catch (e) {
      print('Error getting image data: $e');
    }
  }

// Add this method to your _DrawingPageState class
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



  Stream<Map<String, dynamic>> getDrawerPlayerInfo() {
    return FirebaseFirestore.instance
        .collection('gameRooms')
        .doc(widget.roomId)
        .collection('players')
        .where('isDrawer', isEqualTo: true)
        .limit(1) // Ensure only one drawer is fetched
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        final data = doc.data();
        return {
          'username': data['username'] ?? 'Unknown',
          'score': data['score'] ?? 0,
        };
      }
      return {
        'username': 'Unknown',
        'score': 0,
      };
    });
  }

  // Function to map score to difficulty
  int _mapScoreToDifficulty(int score) {
    if (score < 30) return 0; // Easy
    if (score < 70) return 1; // Medium
    return 2; // Hard
  }

  void removePlayerFromGameRoom(String roomId) async {
    final _authentication = FirebaseAuth.instance;

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
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor:Colors.blueAccent,
      body: Row(
        children: [
          // Drawing area
          Expanded(
            child: Stack(
              children: <Widget>[
                // Main content
                Column(
                  children: <Widget>[
                    // Prompt Word
                    SizedBox(height: 25),
                    Text(
                      promptWord,
                      style: TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    Transform.translate(
                      offset: isTimeLow
                          ? Offset(5 * (0.5 - _timerController.value), 0)
                          : Offset(0, 0),
                      child: Container(
                        width: MediaQuery
                            .of(context)
                            .size
                            .width *
                            (timeWidth / first_timeWidth),
                        height: 3,
                        color: timeColor,
                      ),
                    ),
                    SizedBox(height: 10),
                    Expanded(
                    child: StreamBuilder<Map<String, dynamic>>(
                     stream: getDrawerPlayerInfo(),
                     builder: (context, snapshot) {
                       // Default difficulty to 0 if no data is available
                        int difficultyOption = 0;

                       if (snapshot.hasData && snapshot.data != null) {
                          final score = snapshot.data!['score'] ?? 0;
                         difficultyOption = _mapScoreToDifficulty(score);
                        }

                       return LayoutBuilder(
                          builder: (BuildContext context,
                             BoxConstraints constraints) {
                           return DrawingBoard(
                             boardPanEnabled: false,
                             boardScaleEnabled: false,
                             transformationController: _transformationController,
                             controller: _drawingController,
                             background: Container(
                               width: constraints.maxWidth,
                                height: constraints.maxHeight,
                                color: Colors.white,
                              ),
                              difficultyOption: difficultyOption,
                            );
                          },
                        );
                      },
                    ),

                    ),
                  ],
                ),

                // Positioned 'Back' button at top-left

              ],
            ),
          ),

          // Player information column
          Container(
            width: 200, // Adjust width as needed
            color: Colors.white,
            child: Stack(
              children: [
                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: getPlayerInfo(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return Center(child: CircularProgressIndicator());
                    }

                    final players = snapshot.data!;
                    // Sort players by score in descending order
                    final sortedPlayers = List<Map<String, dynamic>>.from(players)
                      ..sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));

                    return Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: sortedPlayers.map((player) {
                            // Find the index in the sorted list to determine ranking
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
                                      // Ranking display
                                      if (rank <= 3)
                                        Positioned(
                                          left: 0,
                                          top: 0,
                                          child: Container(
                                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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

                                      // Rest of the player card content remains the same
                                      Column(
                                        children: [
                                          CircleAvatar(
                                            radius: 30,
                                            backgroundColor: Colors.blueAccent.withOpacity(0.7),
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
                                            mainAxisAlignment: MainAxisAlignment.center,
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
                Positioned(
                  bottom: 20,
                  right: 40,
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
              ],
            ),
          ),
        ],
      ),

    );
  }
}
