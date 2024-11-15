import 'package:flutter/material.dart';
import 'drawing_board_module_test.dart'; // Assuming this is the page for drawing functionality
import 'guessingPage.dart'; // Assuming this is the page for viewing the drawing

class Selectorder extends StatefulWidget {
  const Selectorder({super.key});

  @override
  State<Selectorder> createState() => _SelectorderState();
}

class _SelectorderState extends State<Selectorder> {
  List<bool> roles = []; // List to hold roles of users (true = drawer, false = viewer)
  bool showMessage = true; // Flag to control whether to show the message

  @override
  void initState() {
    super.initState();

    // Decide the number of total users and drawers
    int totalUsers = 4;  // There are 4 users in total
    int numDrawers = 1;  // One drawer and the rest are viewers

    // Initialize the roles list where one user is always a drawer (true)
    roles = List.generate(totalUsers, (index) {
      return false; // Start with all viewers (false)
    });

    // Randomly select one user to be the drawer
    roles[0] = true; // First user is always the drawer for consistency
    // Randomly pick one index to be the drawer
    int drawerIndex = 0;
    if (drawerIndex != 0) {  // Ensure it's not always the first one
      drawerIndex = (roles.indexOf(false)); // Get the index of a viewer
    }
    roles[drawerIndex] = true; // Assign a drawer

    // After 5 seconds, hide the message and start the game
    Future.delayed(const Duration(seconds: 5), () {
      setState(() {
        showMessage = false; // Hide the "Game will start" message
      });

      // Navigate based on the user's role after 5 seconds
      if (roles[0]) {
        // First user is a drawer
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => DrawingPage()), // Drawer page
        );
      } else {
        // First user is a viewer
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ViewerPage()), // Viewer page
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.black,
                  width: 1.0,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: ElevatedButton(
                onPressed: () {
                  // Temporary action: force navigation to DrawingPage for testing
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => DrawingPage()),
                  );
                },
                child: Text("임시 버튼", style: TextStyle(fontSize: 20)),
              ),
            ),
          ],
        ),
      ),
      body: Center(
        child: Stack(
          children: [
            // If the message is still being shown (within the first 5 seconds)
            if (showMessage)
              Center(
                child: Text(
                  "5초 후에 게임 시작합니다",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            // Chat container
            Align(
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.black,
                        width: 1.0,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    width: 500,
                    height: 500,
                  ),
                ),
              ),
            ),
            // Emojis around the chat container (for fun visual design)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Align(
                alignment: Alignment.topLeft,
                child: Icon(Icons.face, size: 50),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Align(
                alignment: Alignment.topRight,
                child: Icon(Icons.face, size: 50),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Icon(Icons.face_3, size: 50),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Align(
                alignment: Alignment.bottomRight,
                child: Icon(Icons.face_4, size: 50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}