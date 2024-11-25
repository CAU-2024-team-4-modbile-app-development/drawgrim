import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_drawing_board/flutter_drawing_board.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:convert';

class ViewerPage extends StatelessWidget {
  const ViewerPage({Key? key}) : super(key: key);

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
              stream: FirebaseDatabase.instance
                  .ref('images')
                  .orderByChild('timestamp')
                  .limitToLast(1)
                  .onValue, // Firebase에서 최신 데이터를 실시간으로 받아옵니다.
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
                  return Center(child: CircularProgressIndicator());
                }

                final data = snapshot.data!.snapshot.value as Map;
                List<MapEntry> sortedEntries = data.entries.toList()
                  ..sort((a, b) => b.value['timestamp'].compareTo(a.value['timestamp']));

                var lastEntry = sortedEntries.first;
                String base64String = lastEntry.value['image_data'];

                // Base64 문자열을 디코딩해서 이미지로 변환
                Uint8List imageData = base64Decode(base64String);
                print("Decoded Image Key: ${lastEntry.key}");

                // AnimatedSwitcher로 이미지를 부드럽게 교체
                return AnimatedSwitcher(
                  duration: Duration(milliseconds: 200), // 애니메이션 시간 설정
                  child: Image.memory(
                    imageData,
                    key: ValueKey<String>(lastEntry.key), // 키를 사용하여 새로운 이미지가 들어오면 교체되도록 함
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}