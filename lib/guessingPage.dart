import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_drawing_board/flutter_drawing_board.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

import 'dart:convert';

class ViewerPage extends StatefulWidget {
  const ViewerPage({Key? key}) : super(key: key);

  @override
  _ViewerPageState createState() => _ViewerPageState();
}

class _ViewerPageState extends State<ViewerPage> {
  final DrawingController _drawingController = DrawingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _drawingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Viewer Page")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              "You are viewing the drawing in real-time.",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: StreamBuilder<DatabaseEvent>(
              stream: FirebaseDatabase.instance.ref('images').onValue,
              //image 필드가 갱신될 때마다 그걸 감지함
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
                  return Center(child: CircularProgressIndicator());
                }

                final data = snapshot.data!.snapshot.value as Map;
                List<MapEntry> sortedEntries = data.entries.toList()
                  ..sort((a, b) => b.value['timestamp'].compareTo(a.value['timestamp']));

                // 가장 최신 항목 가져오기
                var lastEntry = sortedEntries.first;
                String base64String = lastEntry.value['image_data'];

                // Base64 문자열 디코딩
                Uint8List imageData = base64Decode(base64String);
                print("Decoded Image Key: ${lastEntry.key}");

                return Image.memory(imageData);
              },
            ),
          ),
        ],
      ),
    );
  }
}