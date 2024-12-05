import 'package:flutter/material.dart';
import 'guessingPage.dart'; // Assuming this is the page for viewing the drawing
import 'package:rive/rive.dart';
import 'drawing_board_module_test.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Selectorder extends StatefulWidget {
  final String roomId;

  const Selectorder({super.key, required this.roomId});

  @override
  State<Selectorder> createState() => _SelectorderState();
}

SMIInput<bool>? _is_drawer;
SMIInput<bool>? _is_viewer;

class _SelectorderState extends State<Selectorder> {
  final _authentication = FirebaseAuth.instance;
  User? loggedUser;

  bool isReady = false; // 준비 상태
  bool isHost = false; // 방장 여부

  Future<void> checkIfHost() async {
    try {
      // Firebase Firestore의 roomId를 사용하여 해당 방의 정보를 가져옴
      final roomRef =
          FirebaseFirestore.instance.collection('gameRooms').doc(widget.roomId);

      final roomSnapshot = await roomRef.get();

      // 방장이 누구인지 확인 (createdBy 필드)
      final createdBy = roomSnapshot['createdBy'];

      // 현재 사용자가 방장과 일치하는지 확인
      if (createdBy == _authentication.currentUser?.email) {
        // 현재 사용자가 방장이라면 Firestore에 사용자 상태 업데이트
        try {
          await roomRef
              .collection('players')
              .doc(_authentication.currentUser!.email)
              .update({
            'isDrawer': true,
            'isViewer': false,
          });
        } catch (e) {
          print('$e');
        }
        // UI 업데이트
        setState(() {
          isHost = true; // 방장 여부
        });
      }else{
        try {
          await roomRef
              .collection('players')
              .doc(_authentication.currentUser!.email)
              .update({
            'isDrawer': false,
            'isViewer': true,
          });
        } catch (e) {
          print('$e');
        }
      }
    } catch (e) {
      // 오류가 발생했을 때 처리
      print('Error checking host: $e');
    }
  }

  void _onRiveInit(Artboard artboard) async {
    await checkIfHost();

    final controller = StateMachineController.fromArtboard(
      artboard,
      'Cards',
    );

    if (controller != null) {
      artboard.addController(controller);

      _is_drawer = controller.findInput<bool>('isDrawer') as SMIBool;

      _is_viewer = controller.findInput<bool>('isViewer') as SMIBool;

      _is_drawer?.value = false;
      _is_viewer?.value = false;
    }

    if (isHost == true) {
      // First user is a drawer
      _is_drawer?.value = true;
      await Future.delayed(const Duration(seconds: 5));

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => DrawingPage(
                  roomId: widget.roomId,
                )), // Drawer page
      );
    } else {
      // First user is a viewer
      _is_viewer?.value = true;
      await Future.delayed(const Duration(seconds: 5));

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => ViewerPage(
                  roomId: widget.roomId,
                )), // Viewer page
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
