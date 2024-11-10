import 'dart:async';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Drawing Puzzle Game',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: DrawingGamePage(),
    );
  }
}

class DrawingGamePage extends StatefulWidget {
  @override
  _DrawingGamePageState createState() => _DrawingGamePageState();
}

class _DrawingGamePageState extends State<DrawingGamePage>
    with SingleTickerProviderStateMixin {
  final String promptWord = "Tree"; // Example word, replace with word bank logic
  List<Offset?> points = [];
  late AnimationController _timerController;
  Color timeColor = Colors.green;
  double timeWidth = 300.0;
  bool isTimeLow = false;

  @override
  void initState() {
    super.initState();
    _timerController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 10), // Set the desired countdown time
    )..addListener(() {
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
  }

  @override
  void dispose() {
    _timerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Drawing Puzzle Game'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Prompt Word
            Text(
              promptWord,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),

            // Drawing Board
            Container(
              height: 300,
              width: 300,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black),
              ),
              child: GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    points.add(details.localPosition);
                  });
                },
                onPanEnd: (details) {
                  points.add(null); // Separate strokes
                },
                child: CustomPaint(
                  painter: DrawingPainter(points),
                ),
              ),
            ),
            SizedBox(height: 20),

            // Time Bar
            Transform.translate(
              offset: isTimeLow ? Offset(5 * (0.5 - _timerController.value), 0) : Offset(0, 0),
              child: Container(
                width: timeWidth,
                height: 10,
                color: timeColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom Painter to render the drawing
class DrawingPainter extends CustomPainter {
  final List<Offset?> points;

  DrawingPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.black
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 4.0;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(DrawingPainter oldDelegate) => oldDelegate.points != points;
}
