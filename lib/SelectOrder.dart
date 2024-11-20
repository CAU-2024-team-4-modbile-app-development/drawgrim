import 'package:flutter/material.dart';
import 'drawing_board_module_test.dart'; // Assuming this is the page for drawing functionality
import 'guessingPage.dart'; // Assuming this is the page for viewing the drawing
import 'package:rive/rive.dart';


class Selectorder extends StatefulWidget {

  const Selectorder({super.key});

  @override
  State<Selectorder> createState() => _SelectorderState();
}

class _SelectorderState extends State<Selectorder> {

  SMIInput<bool>? _is_drawer;
  SMIInput<bool>? _is_viewer;

  void _onRiveInit(Artboard artboard) {
    print("ONINIT 실행됨");

    final controller = StateMachineController.fromArtboard(
      artboard,
      'State Machine 1',
      // onStateChange: _onStateChange,
    );

    if (controller != null) {
      print("CONTROLLER IS NOT NULL");
      artboard.addController(controller);

      _is_drawer =
      controller.findInput<bool>('draw') as SMIBool;

      if (_is_drawer == null) {
        print("NULL 값임");
      }

      _is_viewer = controller.findInput<bool>('is_green_on') as SMIBool;

      _is_drawer?.value = false;
      _is_viewer?.value = false;
    }else{
      print("CONTROLLER IS NULL");
    }

  }

  List<bool> roles = []; // List to hold roles of users (true = drawer, false = viewer)
  bool showMessage = true; // Flag to control whether to show the message

  @override
  void initState() {
    super.initState();
    print("INITIate");

    // Decide the number of total users and drawers
    int totalUsers = 5;  // Assume there are 5 users
    int numDrawers = 1;  // Start with at least 1 drawer

    // Initialize the roles list with the first user as the drawer
    roles = List.generate(totalUsers, (index) {
      // Ensure the first user is always a drawer
      if (index == 0) return true;

      // Randomly assign the remaining users as drawers or viewers
      return index < numDrawers + 1 ? true : false; // Adjust numDrawers for additional drawers
    });

    // Shuffle the roles list (but keep the first item as drawer)
    roles.shuffle();

    // After 5 seconds, hide the message and start the game
    // Future.delayed(const Duration(seconds: 10), () {
    //   setState(() {
    //     showMessage = false; // Hide the "Game will start" message
    //   });
    //
    //   // Navigate based on the user's role after 5 seconds
    //   if (roles[0]) {
    //     // First user is a drawer
    //     Navigator.pushReplacement(
    //       context,
    //       MaterialPageRoute(builder: (context) => DrawingPage()), // Drawer page
    //     );
    //   } else {
    //     // First user is a viewer
    //     Navigator.pushReplacement(
    //       context,
    //       MaterialPageRoute(builder: (context) => ViewerPage()), // Viewer page
    //     );
    //   }
    // });
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
                // child: Text(
                //   "5초 후에 게임 시작합니다",
                //   style: TextStyle(
                //     fontSize: 24,
                //     fontWeight: FontWeight.bold,
                //     color: Colors.black,
                //   ),
                // ),
                child: RiveAnimation.asset(
                  "asset/shuffle_drawer_and_viewer.riv",
                  fit: BoxFit.contain,
                  onInit: _onRiveInit,
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
