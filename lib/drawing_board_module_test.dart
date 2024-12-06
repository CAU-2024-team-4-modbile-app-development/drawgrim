import 'dart:math';

import 'package:drawgrim/testGuessingPage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:new_drawing_board_package/new_drawing_board.dart';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
//import 'package:flutter_drawing_board/flutter_drawing_board.dart'
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

class _DrawingPageState extends State<DrawingPage> with SingleTickerProviderStateMixin {
  final DrawingController _drawingController = DrawingController();

  late AnimationController _timerController;
  final TransformationController _transformationController = TransformationController();
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
      _getImageData();
      print("SEX");
    });
    //upload image every 1 second
  }

  /// Called when the timer finishes
  void _onTimerComplete() async {
    final CollectionReference playersRef = FirebaseFirestore.instance
        .collection('gameRooms')
        .doc(widget.roomId)
        .collection('players');

    final QuerySnapshot querySnapshot = await playersRef.orderBy(
        FieldPath.documentId).get();

    for (var doc in querySnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      if (data['isDrawer'] == true && data['isViewer'] == false) {
        await playersRef.doc(doc.id).update({
          'isDrawer': false,
          'isViewer': true,
        });
      }
      else if (data['isDrawer'] == false && data['isViewer'] == true) {
        await playersRef.doc(doc.id).update({
          'isDrawer': true,
          'isViewer': false,
        });
        break;
      }
    }

    Navigator.pushReplacement(context, MaterialPageRoute(
        builder: (context) => ViewerPage(roomId: widget.roomId)));
  }


  @override
  void dispose() {
    _timerController.dispose();
    _drawingController.dispose();
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

    if (images != null && images.length > 10) {
      // 오래된 데이터 삭제
      var sortedKeys = images.keys.toList()
        ..sort((a, b) =>
            images[a]['timestamp'].compareTo(images[b]['timestamp']));

      for (int i = 0; i < images.length - 10; i++) {
        await databaseRef.child(sortedKeys[i]).remove();
      }
    }

    print("Uploaded Image and cleaned up old entries.");
  }


  /// Capture the drawing data as image and upload
  Future<void> _getImageData() async {
    final Uint8List? data = (await _drawingController.getImageData())?.buffer
        .asUint8List();
    if (data == null) {
      debugPrint('Failed to get image data');
      return;
    }
    // Upload the image to Firebase
    //await testUploadImage();


    await _uploadImage(data);
  }

  Stream<List<Map<String, dynamic>>> getPlayerInfo() {
    return FirebaseFirestore.instance
        .collection('gameRooms')
        .doc(widget.roomId)
        .collection('players')
        .where('isViewer',
        isEqualTo: true) // Only fetch players where isViewer is true
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) {
          return {
            'username': doc.data()['username'] ?? 'Unknown',
            'score': doc.data()['score'] ?? 0,
          };
        }).toList());
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
      backgroundColor: Colors.grey,
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
                      child: LayoutBuilder(
                        builder: (BuildContext context,
                            BoxConstraints constraints) {
                          return DrawingBoard(
                            boardPanEnabled: false,
                            boardScaleEnabled: false,
                            transformationController:
                            _transformationController,
                            controller: _drawingController,
                            background: Container(
                              width: constraints.maxWidth,
                              height: constraints.maxHeight,
                              color: Colors.white,
                            ),
                            difficultyOption: 0,
                          );
                          // DRAWING BOARD
                        },
                      ),
                    ),
                  ],
                ),

                // Positioned 'Back' button at top-left
                Positioned(
                  top: 20,
                  left: 20,
                  child: ElevatedButton(
                    onPressed: () {
                      removePlayerFromGameRoom(widget.roomId);
                      Navigator.of(context).pop();
                    },
                    child: Text('Back'),
                  ),
                ),
              ],
            ),
          ),

          // Player information column
          Container(
            width: 200, // Adjust width as needed
            color: Colors.white,
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: getPlayerInfo(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Text(
                      'No viewers yet',
                      style: TextStyle(fontSize: 16),
                    ),
                  );
                }

                final players = snapshot.data!;

                return ListView.builder(
                  itemCount: players.length,
                  itemBuilder: (context, index) {
                    final player = players[index];
                    final username = player['username'];
                    final score = player['score'] ?? 0;
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          // Emoji face
                          Icon(
                            Icons.face,
                            size: 50,
                            color: Colors.white,
                          ),
                          SizedBox(width: 8),
                          // Player info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  username,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Score: $score',
                                  style: TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}