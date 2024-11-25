import 'package:flutter/material.dart';
import 'drawing_board_module_test.dart'; // Assuming this is the page for drawing functionality
import 'guessingPage.dart'; // Assuming this is the page for viewing the drawing
import 'package:rive/rive.dart';

class DecideSubject extends StatefulWidget {
  const DecideSubject({super.key});

  @override
  State<DecideSubject> createState() => _DecideSubjectState();
}

SMIInput<bool>? _isFood;
SMIInput<bool>? _isPlant;
SMIInput<bool>? _isAnimal;

class _DecideSubjectState extends State<DecideSubject> {
  void _onRiveInit(Artboard artboard) async{

    final controller = StateMachineController.fromArtboard(
      artboard,
      'Cards',
      // onStateChange: _onStateChange,
    );

    if (controller != null) {
      artboard.addController(controller);

      _isFood = controller.findInput<bool>('isFood') as SMIBool;
      _isPlant = controller.findInput<bool>('isPlant') as SMIBool;
      _isAnimal = controller.findInput<bool>('isAnimal') as SMIBool;

      _isFood?.value = false;
      _isAnimal?.value = false;
      _isPlant?.value = true;
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Center(
          child: RiveAnimation.asset(
            "asset/제비뽑기.riv",
            fit: BoxFit.contain,
            onInit: _onRiveInit,
          ),
        ),
      ),
    );
  }
}
