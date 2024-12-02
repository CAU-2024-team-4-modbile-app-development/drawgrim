import 'dart:math';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:rive/rive.dart' as rive;

class ViewerPage extends StatefulWidget {
  const ViewerPage({Key? key}) : super(key: key);

  @override
  State<ViewerPage> createState() => _ViewerPageState();
}

class _ViewerPageState extends State<ViewerPage> {
  final String wordToGuess = "APPLE"; // Example word to guess
  late List<String?> guessedLetters;

  @override
  void initState() {
    super.initState();
    guessedLetters = List.filled(wordToGuess.length, null); // Initialize empty guesses
  }

  void _updateGuess(int index, String letter) {
    setState(() {
      guessedLetters[index] = letter.toUpperCase(); // Ensure uppercase
    });
  }

  Future<void> _showLetterInputDialog(int index) async {
    String? letter = await showDialog<String>(
      context: context,
      builder: (context) {
        final TextEditingController letterController = TextEditingController();
        return AlertDialog(
          title: Text("Enter a letter"),
          content: TextField(
            controller: letterController,
            maxLength: 1,
            decoration: InputDecoration(hintText: "Enter a single letter"),
          ),
          actions: [
            TextButton(
              onPressed: () {
                String input = letterController.text.trim().toUpperCase();
                if (input.isNotEmpty && input.length == 1 && RegExp(r'^[A-Z]$').hasMatch(input)) {
                  Navigator.of(context).pop(input);
                } else {
                  Navigator.of(context).pop();
                }
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

    if (letter != null) {
      _updateGuess(index, letter);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(wordToGuess.length, (index) {
            return GestureDetector(
              onTap: () => _showLetterInputDialog(index),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                  decoration: BoxDecoration(
                    color: guessedLetters[index] != null ? Colors.green[100] : Colors.grey[300],
                    border: Border.all(color: Colors.black, width: 1),
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                  child: Text(
                    guessedLetters[index] ?? "_", // Display guessed letter or underscore
                    style: TextStyle(
                      fontSize: 24, // Increased font size
                      fontWeight: FontWeight.bold,
                      color: guessedLetters[index] != null ? Colors.green[700] : Colors.black,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
        centerTitle: true,
      ),
      body: Row(
        children: [
          // Central drawing board
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: Center(
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
                ),
              ],
            ),
          ),
          // Players column with Rive animations
          Container(
            width: 120,
            color: Colors.grey[200],
            child: ListView.builder(
              itemCount: 4,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 60,
                        child: rive.RiveAnimation.asset(
                          'assets/test.riv',
                          fit: BoxFit.contain,
                          animations: const [],
                        ),
                      ),
                      Text("Player ${index + 1}", style: TextStyle(fontSize: 12)),
                      Text("Score: ${index * 10}", style: TextStyle(fontSize: 10)),
                    ],
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
