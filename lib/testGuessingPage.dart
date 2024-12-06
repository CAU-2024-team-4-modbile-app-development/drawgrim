import 'dart:math';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

import 'NewMessage.dart';

class ViewerPage extends StatefulWidget {
  final String roomId;
  const ViewerPage({super.key, required this.roomId});

  @override
  State<ViewerPage> createState() => _ViewerPageState();
}

class _ViewerPageState extends State<ViewerPage> {

  final _controller = TextEditingController();  //입력 값 받아옴(실시간)


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
          // Central drawing board
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    // child: StreamBuilder<DatabaseEvent>(
                    //   stream: FirebaseDatabase.instance
                    //       .ref('images')
                    //       .orderByChild('timestamp')
                    //       .limitToLast(1)
                    //       .onValue,
                    //   builder: (context, snapshot) {
                    //     if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
                    //       return Center(child: CircularProgressIndicator());
                    //     }
                    //
                    //     final data = snapshot.data!.snapshot.value as Map;
                    //     List<MapEntry> sortedEntries = data.entries.toList()
                    //       ..sort((a, b) => b.value['timestamp'].compareTo(a.value['timestamp']));
                    //
                    //     var lastEntry = sortedEntries.first;
                    //     String base64String = lastEntry.value['image_data'];
                    //
                    //     Uint8List imageData = base64Decode(base64String);
                    //
                    //     return AnimatedSwitcher(
                    //       duration: Duration(milliseconds: 200),
                    //       child: Image.memory(
                    //         imageData,
                    //         key: ValueKey<String>(lastEntry.key),
                    //       ),
                    //     );
                    //   },
                    // ),
                  ),
                ),
              ],
            ),
          ),
          // Players column with Rive animations

        ],
      ),
    );
  }
}


