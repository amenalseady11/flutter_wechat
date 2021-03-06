import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_wechat/pages/chat/widgets/message_image.dart';
import 'package:flutter_wechat/pages/chat/widgets/message_voice.dart';
import 'package:flutter_wechat/pages/chat/widgets/triangle_painter.dart';
import 'package:flutter_wechat/providers/chat_message/chat_message.dart';
import 'package:flutter_wechat/util/adapter/adapter.dart';
import 'package:flutter_wechat/util/style/style.dart';
import 'package:flutter_wechat/widgets/avatar/avatar.dart';
import 'package:flutter_wechat/widgets/rotation/rotation.dart';

import 'message_text.dart';

class ChatMessage extends StatelessWidget {
  final ChatMessageProvider message;

  const ChatMessage({Key key, this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (message.type == MessageType.addFriend) {
      return _buildTipMsg(context);
    }

    if (message.type == MessageType.addGroup) {
      return _buildTipMsg(context);
    }

    if (message.type == MessageType.addGroupV2) {
      return _buildTipMsg(context);
    }

    if (message.type == MessageType.expelGroup) {
      return _buildTipMsg(context);
    }

    List<Widget> children = [];
    if (message.type == MessageType.urlImg)
      children = _layout2(context);
    else
      children = _layout1(context);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: ew(20), vertical: ew(12)),
      child: Row(
        mainAxisAlignment:
            message.isSelf ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  /// 文本与语音消息布局
  List<Widget> _layout1(BuildContext context) {
    var size = ew(30);
    if (message.isSelf) {
      return ([
        _buildMsg(context),
        Transform.translate(
          offset: Offset(-ew(8), ew((64 - 30) / 2)),
          child: Transform.rotate(
            angle: -math.pi / 2,
            child: CustomPaint(
                painter: TrianglePainter(Color(0xff9def71)),
                size: Size(size, size)),
          ),
        ),
        _buildAvatar(context),
      ]);
    }

    return ([
      _buildAvatar(context),
      Transform.translate(
        offset: Offset(ew(8), ew((64 - 30) / 2)),
        child: Transform.rotate(
          angle: math.pi / 2,
          child: CustomPaint(
              painter: TrianglePainter(Colors.white), size: Size(size, size)),
        ),
      ),
      _buildMsg(context),
    ]);
  }

  /// 图片消息布局
  List<Widget> _layout2(BuildContext context) {
    if (message.isSelf) {
      return [_buildMsg(context), _buildAvatar(context)];
    }

    return [_buildAvatar(context), _buildMsg(context)];
  }

  Widget _buildTipMsg(BuildContext context) {
    return Container(
        padding: EdgeInsets.symmetric(vertical: ew(10)),
        child: Text(message.body.toString(),
            textAlign: TextAlign.center,
            style: TextStyle(color: Style.sTextColor, fontSize: sp(24))));
  }

  Widget _buildAvatar(BuildContext context) {
    return CAvatar(
        avatar: message.fromAvatar,
        size: ew(76),
        radius: ew(8),
        color: Colors.white);
  }

  Widget _buildMsg(BuildContext context) {
    Widget child;
    if (message.type == MessageType.text)
      child = MessageText(message: message);
    else if (message.type == MessageType.urlImg)
      child = MessageImage(message: message);
    else if (message.type == MessageType.urlVoice)
      child = MessageVoice(message: message);
    else
      child = MessageText(message: message);

    if (!message.isSelf) return child;

    // 请求/发送中
    if (message.status == ChatMessageStatus.sending) {
      return Row(mainAxisAlignment: MainAxisAlignment.end, children: <Widget>[
        Rotation(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: ew(10), vertical: ew(10)),
            child: SvgPicture.asset("assets/images/icons/loading.svg",
                width: ew(32), height: ew(32), color: Colors.redAccent),
          ),
        ),
        child,
      ]);
    }

    // 请求/发送错误
    if (message.status == ChatMessageStatus.sendError) {
      return Row(mainAxisAlignment: MainAxisAlignment.end, children: <Widget>[
        Container(
            padding: EdgeInsets.all(ew(10)),
            child: Icon(Icons.error, color: Colors.redAccent, size: sp(32))),
        child,
      ]);
    }

    return child;
  }
}
