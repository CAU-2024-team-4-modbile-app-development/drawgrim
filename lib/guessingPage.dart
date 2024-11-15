import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_drawing_board/flutter_drawing_board.dart';
import 'package:flutter_drawing_board/paint_contents.dart';

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
    _listenToDrawingUpdates();
  }

  // Listen to Firestore for updates
  void _listenToDrawingUpdates() {
    FirebaseFirestore.instance
        .collection('drawings')
        .doc('shared_drawing')
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data()?['drawingData'] as List<dynamic>;
        final List<PaintContent> contents = data.map((item) {
          return _paintContentFromJson(item as Map<String, dynamic>);
        }).toList();

        // Clear the current drawing and add the new data
        _drawingController.clear();
        _drawingController.addContents(contents);
      }
    });
  }

  PaintContent _paintContentFromJson(Map<String, dynamic> json) {
    switch (json['type']) {
      case 'StraightLine':
        return StraightLine.fromJson(json);
      case 'SimpleLine':
        return SimpleLine.fromJson(json);
      case 'Eraser':
        return Eraser.fromJson(json);
      default:
        throw UnsupportedError('Unknown paint content type: ${json['type']}');
    }
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
            child: DrawingBoard(
              controller: _drawingController,
              boardPanEnabled: false,
              boardScaleEnabled: false,
              showDefaultTools: false, // Hide tools on viewer page
              background: Container(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}