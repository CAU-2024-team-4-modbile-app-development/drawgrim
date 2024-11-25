import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

class Ranking extends StatefulWidget {
  String? first;
  String? second;
  String? third;

  Ranking({
    super.key,
    required this.first,
    required this.second,
    required this.third,
  });

  @override
  State<Ranking> createState() => _RankingState();
}

class _RankingState extends State<Ranking> {
  void _onRiveInit(Artboard artboard) async {
    final controller = StateMachineController.fromArtboard(
      artboard,
      'State Machine 1',
      // onStateChange: _onStateChange,
    );

    if (controller != null) {
      artboard.addController(controller);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Flexible(
            flex: 10,
            child: Stack(
              children: [
                Positioned.fill(
                  child: RiveAnimation.asset(
                    "asset/medal.riv",
                    fit: BoxFit.contain,
                    onInit: _onRiveInit,
                  ),
                ),

                Positioned(
                  top: 500,
                  left: 125,
                  child: Text(
                    widget.second ?? "",
                    style: TextStyle(
                      fontSize: 50,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          blurRadius: 4.0,
                          color: Colors.black.withOpacity(0.5),
                          offset: Offset(2.0, 2.0),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Positioned(
                  top: 500,
                  left: 375,
                  child: Text(
                    widget.first ?? "",
                    style: TextStyle(
                      fontSize: 50,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          blurRadius: 4.0,
                          color: Colors.black.withOpacity(0.5),
                          offset: Offset(2.0, 2.0),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Positioned(
                  top: 500,
                  left: 600,
                  child: Text(
                    widget.third ?? "",
                    style: TextStyle(
                      fontSize: 50,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          blurRadius: 4.0,
                          color: Colors.black.withOpacity(0.5),
                          offset: Offset(2.0, 2.0),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

              ],
            ),
          ),
          Flexible(
            flex: 1,
            child: ElevatedButton(
              onPressed: () {
                // Navigator.pop(context);
              },
              child: Text(
                "나가기",
                style: TextStyle(fontSize: 40),
              ),
            ),
          ),
        ],
      ),
    );

  }
}
