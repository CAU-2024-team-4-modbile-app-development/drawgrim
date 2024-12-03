import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:rive/rive.dart';
import 'SelectOrder.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  String subject = '';

  void _onRiveInit(Artboard artboard) async {
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

      final roomRef =
          FirebaseFirestore.instance.collection('gameRooms').doc(widget.roomId);
      final QuerySnapshot subjectSnapshot =
          await roomRef.collection('subject').get();

      final String subject = subjectSnapshot.docs.first['subject'];

      switch (subject) {
        case 'food':
          _isFood?.value = true;
          break;
        case 'animal':
          _isAnimal?.value = true;
          break;
        case 'plant':
          _isPlant?.value = true;
          break;
      }
    }
  }

  void _onStateChange(String stateMachineName, String stateName) async {
    if (stateName == 'ExitState') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => Selectorder(
                  roomId: widget.roomId,
                )), // Drawer page
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
