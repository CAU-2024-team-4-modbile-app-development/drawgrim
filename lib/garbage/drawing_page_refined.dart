import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_drawing_board/flutter_drawing_board.dart';
import 'package:flutter_drawing_board/paint_contents.dart';
import 'test_data.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Puzzle Drawing Game',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const PuzzleDrawingPage(),
    );
  }
}

class PuzzleDrawingPage extends StatefulWidget {
  const PuzzleDrawingPage({Key? key}) : super(key: key);

  @override
  State<PuzzleDrawingPage> createState() => _PuzzleDrawingPageState();
}

class _PuzzleDrawingPageState extends State<PuzzleDrawingPage>
    with SingleTickerProviderStateMixin {
  final DrawingController _drawingController = DrawingController();
  final List<String> _keywords = ['Sun', 'House', 'Tree', 'Car', 'Dog']; // Example words
  String _currentKeyword = '';
  late AnimationController _timerController;
  Color _timeBarColor = Colors.green;
  double _timeRemaining = 1.0;

  @override
  void initState() {
    super.initState();
    _setRandomKeyword();
    _initializeTimer();
  }

  void _initializeTimer() {
    _timerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10), // Set desired duration here
    )..addListener(() {
      setState(() {
        _timeRemaining = _timerController.value;
        _timeBarColor = _getTimeBarColor();
      });
    });

    _timerController.forward();
  }

  void _setRandomKeyword() {
    _currentKeyword = _keywords[Random().nextInt(_keywords.length)];
  }

  Color _getTimeBarColor() {
    if (_timerController.value < 0.2) {
      return Colors.red;
    } else if (_timerController.value < 0.5) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }

  @override
  void dispose() {
    _drawingController.dispose();
    _timerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Draw the Keyword'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: _drawingController.clear,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Keyword: $_currentKeyword',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
          Expanded(
            child: DrawingBoard(
              controller: _drawingController,
              showDefaultActions: false,
              showDefaultTools: false,
              defaultToolsBuilder: (Type t, _) {
                return [
                  DefToolItem(
                    icon: Icons.edit,
                    isActive: t == 'SimpleLine',
                    onTap: () => _drawingController.setPaintContent(SimpleLine.fromJson(tData[0])),
                  ),
                  DefToolItem(
                    icon: Icons.clear,
                    isActive: t == 'Eraser',
                    onTap: () => _drawingController.setPaintContent(Eraser.fromJson(tData[1])),
                  ),
                ];
              },
              background: Container(color: Colors.white),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: LinearProgressIndicator(
              value: 1 - _timeRemaining,
              color: _timeBarColor,
              backgroundColor: Colors.grey.shade300,
            ),
          ),
        ],
      ),
    );
  }
}
