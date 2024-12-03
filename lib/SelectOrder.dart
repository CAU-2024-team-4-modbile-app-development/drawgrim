import 'package:flutter/material.dart';
import 'drawing_board_module_test.dart'; // Assuming this is the page for drawing functionality
import 'testGuessingPage.dart';
//import 'guessingPage.dart'; // Assuming this is the page for viewing the drawing
import 'package:rive/rive.dart';

class Selectorder extends StatefulWidget {
  final String roomId;

  const Selectorder({super.key, required this.roomId});

  @override
  State<Selectorder> createState() => _SelectorderState();
}

List<bool> roles = []; // List to hold roles of users (true = drawer, false = viewer)

int totalUsers = 5; // Assume there are 5 users
int numDrawers = 1; // Start with at least 1 drawer

SMIInput<bool>? _is_drawer;
SMIInput<bool>? _is_viewer;

class _SelectorderState extends State<Selectorder> {
  void _onRiveInit(Artboard artboard) async{
    
    print("ONINIT 실행됨");

    final controller = StateMachineController.fromArtboard(
      artboard,
      'Cards',
      // onStateChange: _onStateChange,
    );

    if (controller != null) {
      artboard.addController(controller);

      _is_drawer = controller.findInput<bool>('isDrawer') as SMIBool;

      _is_viewer = controller.findInput<bool>('isViewer') as SMIBool;

      _is_drawer?.value = false;
      _is_viewer?.value = false;
    }

    roles = List.generate(totalUsers, (index) {
      // Ensure the first user is always a drawer
      if (index == 0)
        return true;
      else {
        return false;
      }
    });

    roles.shuffle();

    if (roles[0]) {
      // First user is a drawer
      _is_drawer?.value = true;
      await Future.delayed(const Duration(seconds: 5));

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => DrawingPage(roomId: widget.roomId,)), // Drawer page
      );
    } else {
      // First user is a viewer
      _is_viewer?.value = true;
      await Future.delayed(const Duration(seconds: 5));

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ViewerPage()), // Viewer page
      );
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "순서 정하기",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Center(
          child: RiveAnimation.asset(
            "assets/제비뽑기.riv",
            fit: BoxFit.contain,
            onInit: _onRiveInit,
          ),
        ),
      ),
    );
  }
}
