import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_wechat/providers/chat/chat.dart';
import 'package:flutter_wechat/providers/contact/contact.dart';
import 'package:flutter_wechat/providers/group/group.dart';
import 'package:flutter_wechat/service/socket_service.dart';
import 'package:flutter_wechat/util/adapter/adapter.dart';
import 'package:flutter_wechat/widgets/rotation/rotation.dart';

class AppBarLoading extends StatefulWidget {
  final ChatProvider chat;

  const AppBarLoading({Key key, this.chat}) : super(key: key);

  @override
  _AppBarLoadingState createState() => _AppBarLoadingState();
}

class _AppBarLoadingState extends State<AppBarLoading> {
  SocketConnectorState state;
  StreamSubscription subscription;
  @override
  void initState() {
    super.initState();
    this.state = socket.getSocketConnectorState(
        private: widget.chat.isContactChat, sourceId: widget.chat.sourceId);

    subscription = socket.listenConnectorState((event) {
      var state = socket.getSocketConnectorState(
          private: widget.chat.isContactChat, sourceId: widget.chat.sourceId);
      if (state == this.state) return;
      this.state = event.state;
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var exists = false;
    if (widget.chat.isContactChat)
      exists = widget.chat.contact.status == ContactStatus.friend;
    else if (widget.chat.isGroupChat)
      exists = widget.chat.group.status == GroupStatus.joined;
    return Offstage(
      offstage: !exists || state == SocketConnectorState.connecting,
      child: Rotation(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: ew(10), vertical: ew(10)),
          child: SvgPicture.asset("assets/images/icons/loading.svg",
              width: ew(32), height: ew(32), color: Colors.grey),
        ),
      ),
    );
  }
}
