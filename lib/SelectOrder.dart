import 'package:flutter/material.dart';

class Selectorder extends StatefulWidget {
  const Selectorder({super.key});

  @override
  State<Selectorder> createState() => _SelectorderState();
}

class _SelectorderState extends State<Selectorder> {
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
                    width: 1.0
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: ElevatedButton(
                onPressed: (){


                },
                child: Text("임시 버튼", style: TextStyle(fontSize: 20),),
              ),
            )
          ],
        ),

      ),

      body: Center(
        child: Stack(
          children: [
            // 채팅창 Container
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
                          width: 1.0
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    width: 500,
                    height: 500,
                  ),
                ),
              ),
            ),
            // 이모티콘들: 채팅방을 둘러싸도록 배치

            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Align(alignment: Alignment.topLeft, child: Icon(Icons.face, size: 50)),
            ),
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Align(alignment: Alignment.topRight, child: Icon(Icons.face, size: 50)),
            ),
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Align(alignment: Alignment.bottomLeft, child: Icon(Icons.face_3, size: 50)),
            ),
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Align(alignment: Alignment.bottomRight, child: Icon(Icons.face_4, size: 50)),
            ),
          ],
        ),
      ),

    );
  }
}
