import 'package:flutter/material.dart';
import 'package:rive/rive.dart';
import 'SelectOrder.dart';
import 'WordsProvider.dart';
import 'package:provider/provider.dart';

import 'dart:math';

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
      onStateChange: _onStateChange,
    );

    if (controller != null) {
      artboard.addController(controller);

      _isFood = controller.findInput<bool>('isFood') as SMIBool;
      _isPlant = controller.findInput<bool>('isPlant') as SMIBool;
      _isAnimal = controller.findInput<bool>('isAnimal') as SMIBool;

      _isFood?.value = false;
      _isAnimal?.value = false;
      _isPlant?.value = false;

      final random = Random();
      final int randomIndex = random.nextInt(3);

      switch(randomIndex){
        case 0:
          _isFood?.value = true;

          break;
        case 1:
          _isAnimal?.value = true;
          break;
        case 2:
          _isPlant?.value = true;
          break;
      }
      //provider 작업 추가 필요
    }
  }

  @override
  void initState() {
    super.initState();
  }

  void _onStateChange(String stateMachineName, String stateName) async {
    if (stateName == 'ExitState') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => Selectorder()), // Drawer page
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("주제 선택"),
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
