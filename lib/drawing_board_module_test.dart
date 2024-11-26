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

// Firebase에서 실시간으로 이미지 데이터를 받아와서 업데이트합니다.
class DrawingPage extends StatefulWidget {
  const DrawingPage({super.key});

  @override
  State<DrawingPage> createState() => _DrawingPageState();
}

class _DrawingPageState extends State<DrawingPage> {
  final DrawingController _drawingController = DrawingController();
  final String promptWord = "애 호 박"; // 예시 단어
  bool isTimeLow = false;

  // Firebase Database에 이미지를 업로드하는 메소드
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

  // 그림 데이터를 주기적으로 Firebase에 업로드
  Future<void> _getImageData() async {
    final Uint8List? data = (await _drawingController.getImageData())?.buffer.asUint8List();
    if (data == null) {
      debugPrint('Failed to get image data');
      return;
    }

    // Firebase에 업로드
    await _uploadImage(data);
  }

  @override
  void initState() {
    super.initState();

    // 일정 시간마다 이미지 데이터를 업로드합니다.
    Timer.periodic(Duration(microseconds: 700), (timer) {
      _getImageData();
      //yum
    });
  }

  @override
  void dispose() {
    _drawingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          Column(
            children: <Widget>[
              SizedBox(height: 25),
              Text(
                promptWord,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Expanded(
                child: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    return DrawingBoard(
                      boardPanEnabled: false,
                      boardScaleEnabled: false,
                      controller: _drawingController,
                      background: Container(
                        width: constraints.maxWidth,
                        height: constraints.maxHeight,
                        color: Colors.white,
                      ),
                      showDefaultActions: true,
                      showDefaultTools: true,
                    );
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