import 'package:flutter/material.dart';
import 'package:flutter_chat_bubble/chat_bubble.dart';

class ChatElement extends StatelessWidget {
  const ChatElement({super.key,this.isMe,this.userName,this.text});
  final bool? isMe;
  final String? userName;
  final String? text;

  @override
  Widget build(BuildContext context) {
    if(isMe!){
      return   Padding(
        padding: const EdgeInsets.only(right:16.0),
        child: ChatBubble(
          clipper: ChatBubbleClipper3(type: BubbleType.sendBubble),
          alignment: Alignment.topRight,
          margin: EdgeInsets.only(top: 20),
          backGroundColor:  Colors.blueAccent,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  userName!,
                  style: const TextStyle(
                      color:  Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 30
                  ),
                ),
                Text(
                  text!,
                  style: TextStyle(color: Colors.white,fontSize: 30),
                ),
              ],
            ),
          ),
        ),
      );
    }
    else {
      return Padding(
        padding: const EdgeInsets.only(left: 16.0),
        child: ChatBubble(
          clipper: ChatBubbleClipper3(type: BubbleType.receiverBubble),
          backGroundColor: Color(0xffE7E7ED),
          margin: EdgeInsets.only(top: 20),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery
                  .of(context)
                  .size
                  .width * 0.7,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName!,
                  style: const TextStyle(
                      color:  Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 30
                  ),
                ),
                Text(
                  text!,
                  style: TextStyle(color: Colors.black,fontSize: 30),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }
}