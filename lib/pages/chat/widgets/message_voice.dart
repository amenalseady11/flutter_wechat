import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:common_utils/common_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_wechat/pages/chat/widgets/voice_animation.dart';
import 'package:flutter_wechat/providers/chat_message/chat_message.dart';
import 'package:flutter_wechat/util/adapter/adapter.dart';
import 'package:provider/provider.dart';

List<String> _voices = [
  "assets/images/icons/left_voice_3.png",
  "assets/images/icons/left_voice_1.png",
  "assets/images/icons/left_voice_2.png",
];

class MessageVoice extends StatefulWidget {
  final ChatMessageProvider message;

  const MessageVoice({Key key, this.message}) : super(key: key);

  @override
  _MessageVoiceState createState() => _MessageVoiceState();
}

class _MessageVoiceState extends State<MessageVoice> {
  int _seconds = 1;

  AudioPlayer _player;

  get voicePath => widget.message.bodyData;

  get isLocal => _player.isLocalUrl(voicePath);

  bool _play = false;
  get play => _play;
  set play(bool play) {
    if (_play == play) return;
    _play = play;
    if (mounted) setState(() {});
  }

  List<StreamSubscription> subscriptions = [];

  @override
  void initState() {
    super.initState();
    _seconds = int.tryParse(voicePath.split("?seconds=").last) ?? 1;
    _player = Provider.of<AudioPlayer>(context, listen: false);
  }

  @override
  void dispose() {
    super.dispose();
    subscriptions
      ..forEach((subscription) => subscription.cancel())
      ..clear();
  }

  Future<int> startPlay() async {
    await stopPlay();
    subscriptions.addAll([
      _player.onPlayerError.listen((bool) {
        LogUtil.v("player/error:" + bool.toString());
        if (play) play = false;
      }),
      _player.onPlayerStateChanged.listen((state) {
        LogUtil.v("player/state:" + state.toString());
        if (play && state != AudioPlayerState.PLAYING) play = false;
      }),
    ]);
    _play = true;
    widget.message.state = ChatMessageStates.voiceAlreadyRead;
    widget.message.serialize();
    if (mounted) setState(() {});
    var rst = await _player.play(voicePath.split("?").first, isLocal: isLocal);
    LogUtil.v("player/start：" + rst.toString());
    return rst;
  }

  Future<int> stopPlay() async {
    try {
      _play = false;
      if (mounted) setState(() {});
      subscriptions
        ..forEach((subscription) => subscription.cancel())
        ..clear();
      var rst = await _player.stop();
      LogUtil.v("player/stop:" + rst.toString());
      return rst;
    } catch (e) {
      return -1;
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> children = widget.message.isSelf
        ? [
            Text(
              "$_seconds\"",
              style: TextStyle(
                  color: Colors.black87.withOpacity(.8),
                  fontSize: sp(30),
                  fontWeight: FontWeight.w400),
            ),
            Transform.translate(
              offset: Offset(ew(20), 0),
              child: Transform.rotate(
                  angle: -math.pi / 1,
                  child: VoiceAnimation(_voices, width: ew(40), isStop: _play)),
            ),
          ]
        : [
            Transform.translate(
              offset: Offset(-ew(20), 0),
              child: VoiceAnimation(_voices, width: ew(40), isStop: _play),
            ),
            Text("$_seconds\"",
                style: TextStyle(
                    color: Colors.black87.withOpacity(.8),
                    fontSize: sp(30),
                    fontWeight: FontWeight.w400)),
          ];
    Widget child = Container(
      padding: EdgeInsets.symmetric(vertical: ew(18), horizontal: ew(20)),
      alignment:
          widget.message.isSelf ? Alignment.centerRight : Alignment.centerLeft,
      decoration: BoxDecoration(
        color: widget.message.isSelf ? Color(0xff9def71) : Color(0xffffffff),
        borderRadius: BorderRadius.all(Radius.circular(4.0)),
      ),
      width: ew(250 / 60 * _seconds + 130),
      constraints: BoxConstraints(
        maxWidth: ew(300),
      ),
      child: Row(
        mainAxisAlignment: widget.message.isSelf
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: children,
      ),
    );

    if (!widget.message.isSelf &&
        widget.message.state == ChatMessageStates.voiceUnRead) {
      child = Row(children: <Widget>[
        child,
        SizedBox(width: ew(10)),
        Container(
          width: ew(16),
          height: ew(16),
          decoration:
              BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
        )
      ]);
    }

    return GestureDetector(
      onTap: () async {
        play ? stopPlay() : startPlay();
      },
      child: child,
    );
  }
}
