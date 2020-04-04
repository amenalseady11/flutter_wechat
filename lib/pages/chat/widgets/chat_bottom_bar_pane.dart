import 'package:flutter/material.dart';
import 'package:flutter_wechat/util/adapter/adapter.dart';
import 'package:flutter_wechat/util/style/style.dart';

class ChatBottomBarPane extends StatelessWidget {
  final Widget child;
  final double height;

  bool get expand => (height ?? 0) > 0;

  const ChatBottomBarPane({Key key, this.height, this.child}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
        width: double.maxFinite,
        height: height,
        duration: Duration(milliseconds: 100),
        margin: expand ? EdgeInsets.symmetric(vertical: ew(10)) : null,
        padding: expand ? EdgeInsets.only(top: ew(12), left: ew(20)) : null,
        decoration: BoxDecoration(
//          color: Colors.red,
          border: Border(
            top: BorderSide(color: Style.pDividerColor, width: 1),
          ),
        ),
        child: SingleChildScrollView(child: child));
  }
}
