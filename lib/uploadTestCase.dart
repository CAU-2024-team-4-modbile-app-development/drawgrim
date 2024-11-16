  import 'package:flutter/material.dart';
  import 'package:flutter_drawing_board/flutter_drawing_board.dart';
  import 'package:firebase_database/firebase_database.dart';
  import 'dart:convert';
  import 'dart:typed_data';
  import 'package:firebase_core/firebase_core.dart';


  Uint8List? decoded_imageData;


  void _listenToDrawingUpdates() async {
    DatabaseReference ref = FirebaseDatabase.instance.ref('images');
    DataSnapshot snapshot = await ref.get();
    //image 필드 하위 목록들 다 가져옴

    if (snapshot.value != null) {
      final data = snapshot.value as Map;
      // 첫 번째 하위 목록 가져옴
      var firstKey = data.keys.first;
      var imageData = data[firstKey]['image_data'];
      decoded_imageData = base64Decode(imageData);
      print(decoded_imageData);
      //디버깅용, decode된 이미지 데이터

      print("encoding된 이미지 데이터: $imageData");
    } else {
      print("이미지 field 비어있음");
    }
  }


  void main() async{
    WidgetsFlutterBinding.ensureInitialized();
    try {
      await Firebase.initializeApp(); // Firebase 초기화
      runApp(const MyApp());
    } catch (e) {
      debugPrint('Failed to initialize Firebase: $e');
    }


    runApp(const MyApp());
  }

  class MyApp extends StatelessWidget {
    const MyApp({super.key});

    @override
    Widget build(BuildContext context) {
      return MaterialApp(
        home: uploadTestCase(),
      );
    }
  }

  Future<void> _uploadImage(Uint8List imageData) async {
    String base64String = base64Encode(imageData);

    DatabaseReference databaseRef =
        FirebaseDatabase.instance.ref('images').push();
    await databaseRef.set({'image_data': base64String});
  }

  final DrawingController _drawingController = DrawingController();

  Future<void> _getImageData() async {
    final Uint8List? data =
        (await _drawingController.getImageData())?.buffer.asUint8List();
    print(data);
    if (data == null) {
      debugPrint('Failed to get image data');
      return;
    }

    await _uploadImage(data);
  }

  class uploadTestCase extends StatefulWidget {
    const uploadTestCase({super.key});

    @override
    State<uploadTestCase> createState() => _uploadTestCaseState();
  }

  class _uploadTestCaseState extends State<uploadTestCase> {
    @override
    Widget build(BuildContext context) {
      return Scaffold(
        body: Stack(
          children: [
            Positioned.fill(
              child: DrawingBoard(
                background: Container(width: 400, height: 400, color: Colors.white),
                controller: _drawingController,
                showDefaultActions: true,
                showDefaultTools: true,
              ),
            ),
            Positioned(
              right: 16,
              bottom: 16,
              child: ElevatedButton(
                onPressed: _getImageData,
                child: Text("Upload"),
              ),
            ),
          ],
        ),
      );
    }
  }
