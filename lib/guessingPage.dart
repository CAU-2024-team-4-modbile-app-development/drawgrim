import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:new_drawing_board_package/new_drawing_board.dart';
//import 'package:flutter_drawing_board/flutter_drawing_board.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:convert';

class ViewerPage extends StatefulWidget {
  final String roomId;

  const ViewerPage({super.key, required this.roomId});

  @override
  State<ViewerPage> createState() => _ViewerPageState();
}

class _ViewerPageState extends State<ViewerPage> {
  void _showGuessDialog(BuildContext context) {
    final TextEditingController guessController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Your Guess"),
          content: TextField(
            controller: guessController,
            decoration: InputDecoration(hintText: "Type your guess here"),
          ),
          actions: [
            TextButton(
              onPressed: () {
                String guess = guessController.text.trim();
                if (guess.isNotEmpty) {
                  _submitGuess(guess);
                }
                Navigator.of(context).pop();
              },
              child: Text("Submit"),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("Cancel"),
            ),
          ],
        );
      },
    );
  }

  void _submitGuess(String guess) {
    // Logic to check the guess and update points
    print("Player guessed: $guess");
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
              "Guess the word based on the drawing!",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                // Central drawing board
                Center(
                  child: StreamBuilder<DatabaseEvent>(
                    stream: FirebaseDatabase.instance
                        .ref('images')
                        .orderByChild('timestamp')
                        .limitToLast(1)
                        .onValue,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
                        return Center(child: CircularProgressIndicator());
                      }

                      final data = snapshot.data!.snapshot.value as Map;
                      List<MapEntry> sortedEntries = data.entries.toList()
                        ..sort((a, b) => b.value['timestamp'].compareTo(a.value['timestamp']));

                      var lastEntry = sortedEntries.first;
                      String base64String = lastEntry.value['image_data'];

                      Uint8List imageData = base64Decode(base64String);

                      return AnimatedSwitcher(
                        duration: Duration(milliseconds: 200),
                        child: Image.memory(
                          imageData,
                          key: ValueKey<String>(lastEntry.key),
                        ),
                      );
                    },
                  ),
                ),
                // Players' characters around the board
                Positioned.fill(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      double boardRadius = constraints.maxWidth / 2 - 20; // Adjust radius
                      return Stack(
                        children: List.generate(4, (index) {
                          double angle = (index * 90) * (3.14 / 180); // 90 degrees per player
                          double x = boardRadius * 0.8 * cos(angle) + constraints.maxWidth / 2;
                          double y = boardRadius * 0.8 * sin(angle) + constraints.maxHeight / 2;

                          // Replace player data with dynamic ones
                          return Positioned(
                            left: x - 20, // Adjust for emoji size
                            top: y - 20,
                            child: Column(
                              children: [
                                Text("Player ${index + 1}", style: TextStyle(fontSize: 12)),
                                CircleAvatar(child: Text("😀")), // Replace with emoji/icon
                                Text("Score: ${index * 10}", style: TextStyle(fontSize: 10)),
                              ],
                            ),
                          );
                        }),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // Word hint
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: InkWell(
              onTap: () => _showGuessDialog(context),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (_) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2.0),
                    child: Container(
                      width: 20,
                      height: 30,
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(width: 2.0)),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}