import 'package:flutter/material.dart';
import 'package:rive/rive.dart';
import 'SelectOrder.dart';
import 'Words.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'dart:math';

class DecideSubject extends StatefulWidget {
  final String roomId;

  const DecideSubject({super.key, required this.roomId});


  @override
  State<DecideSubject> createState() => _DecideSubjectState();
}

SMIInput<bool>? _isFood;
SMIInput<bool>? _isPlant;
SMIInput<bool>? _isAnimal;


class _DecideSubjectState extends State<DecideSubject> {

  bool isHost = false; // 방장 여부

  void _onRiveInit(Artboard artboard) async{
    String subject = "";

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

      _isFood?.value = true;
      subject = "food";

      await updateSubject(subject);

      //Food로 고정
    }
  }

  @override
  void initState() {
    super.initState();
  }

  Future<void> updateSubject(String subject)async{
    Words words = Words();


    await FirebaseFirestore.instance
        .collection('gameRooms')
        .doc(widget.roomId)
        .collection('subject')
        .add({
      'subject': subject,
      'elements': words.returnSubjectList(subject),
    });
  }

  void _onStateChange(String stateMachineName, String stateName) async {
    if (stateName == 'ExitState') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => Selectorder(roomId: widget.roomId,)), // Drawer page
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "주제 선택",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true, // 제목 중앙 정렬
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
