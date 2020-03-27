import 'package:flutter/material.dart';
import 'package:flutter_wechat/providers/chat_message/chat_message.dart';
import 'package:flutter_wechat/util/adapter/adapter.dart';

class MessageText extends StatelessWidget {
  final ChatMessageProvider message;

  const MessageText({Key key, this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: ew(18), horizontal: ew(20)),
      decoration: BoxDecoration(
        color: message.isSelf ? Color(0xff9def71) : Color(0xffffffff),
        borderRadius: BorderRadius.all(Radius.circular(4.0)),
      ),
      constraints: BoxConstraints(
        maxWidth: ew(500),
      ),
      child: Text(message.body ?? "",
          style: TextStyle(
              color: Colors.black87.withOpacity(.8),
              fontSize: sp(30),
              fontWeight: FontWeight.w400)),
    );
  }
}
