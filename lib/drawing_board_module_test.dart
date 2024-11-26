import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_drawing_board/flutter_drawing_board.dart';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_database/firebase_database.dart';
import 'dart:convert'; //데이터 base64로 변환

import 'dart:async';

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
      home: const DrawingPage(),
    );
  }
}

class DrawingPage extends StatefulWidget {
  const DrawingPage({super.key});

  @override
  State<DrawingPage> createState() => _DrawingPageState();
}

class _DrawingPageState extends State<DrawingPage> with SingleTickerProviderStateMixin {
  final DrawingController _drawingController = DrawingController();
  final String promptWord = "애 호 박";
  late AnimationController _timerController;
  final TransformationController _transformationController = TransformationController();
  Color timeColor = Colors.green;
  final double first_timeWidth = 300.0;
  double timeWidth = 300.0;
  bool isTimeLow = false;

  double _colorOpacity = 1;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
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
      });

    // Start the timer when the game starts
    _timerController.forward();

    Timer? _timer;
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      _getImageData();
    });
    //1초마다 이미지 업로드
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

    // 새 이미지 업로드
    await newImageRef.set({
      'image_data': base64String,
      'timestamp': ServerValue.timestamp,
    });

    // 데이터 정리: 최신 10개만 유지
    DatabaseEvent event = await databaseRef.orderByChild('timestamp').once();
    DataSnapshot snapshot = event.snapshot;

    Map<dynamic, dynamic>? images = snapshot.value as Map?;

    if (images != null && images.length > 10) {
      // 오래된 데이터 삭제
      var sortedKeys = images.keys.toList()
        ..sort((a, b) => images[a]['timestamp'].compareTo(images[b]['timestamp']));

      for (int i = 0; i < images.length - 10; i++) {
        await databaseRef.child(sortedKeys[i]).remove();
      }
    }

    print("Uploaded Image and cleaned up old entries.");
  }


  /// Capture the drawing data as image and upload
  Future<void> _getImageData() async {
    final Uint8List? data = (await _drawingController.getImageData())?.buffer.asUint8List();
    if (data == null) {

      debugPrint('Failed to get image data');
      return;
    }
    // Upload the image to Firebase
    //await testUploadImage();


    await _uploadImage(data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.grey,
      body: Stack(
        children: <Widget>[
          // Main content
          Column(
            children: <Widget>[
              // Prompt Word
              SizedBox(height: 25),
              Text(
                promptWord,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Transform.translate(
                offset: isTimeLow ? Offset(5 * (0.5 - _timerController.value), 0) : Offset(0, 0),
                child: Container(
                  width: MediaQuery.of(context).size.width * (timeWidth / first_timeWidth),
                  height: 3,
                  color: timeColor,
                ),
              ),
              SizedBox(height: 10),
              Expanded(
                child: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
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
                      showDefaultActions: true,
                      showDefaultTools: true,
                    );
                    //DRAWING BOARD
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
                Navigator.of(context).pop();
              },
              child: Text('Back'),
            ),
          ),
        ],
      ),
    );
  }
}