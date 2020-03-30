import 'package:flutter/material.dart';
import 'package:flutter_wechat/providers/chat/chat.dart';
import 'package:flutter_wechat/providers/contact/contact.dart';
import 'package:flutter_wechat/providers/group/group.dart';
import 'package:flutter_wechat/socket/socket.dart';
import 'package:flutter_wechat/util/adapter/adapter.dart';
import 'package:flutter_wechat/widgets/rotation/rotation.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

class AppBarLoading extends StatelessWidget {
  final ChatProvider chat;

  const AppBarLoading({Key key, this.chat}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    var socketState = socket.getSocketState(
        private: chat.isContactChat, sourceId: chat.sourceId);
    return StreamProvider.value(
      initialData: socketState,
      value: socket.stateStream.stream,
      updateShouldNotify: (SocketState prev, SocketState next) {
        if (prev.sourceId != next.sourceId) return false;
        if (prev.state == next.state) return false;
        return true;
      },
      child: Consumer<SocketState>(
        builder: (context, ss, child) {
          var exists = false;
          if (chat.isContactChat)
            exists = chat.contact.status == ContactStatus.normal;
          else if (chat.isGroupChat)
            exists = chat.group.status == GroupStatus.joined;
          return Offstage(
            offstage: !exists || ss.state == SocketStateEnum.connecting,
            child: Rotation(
              child: Container(
                padding:
                    EdgeInsets.symmetric(horizontal: ew(10), vertical: ew(10)),
                child: SvgPicture.asset("assets/images/icons/loading.svg",
                    width: ew(32), height: ew(32), color: Colors.grey),
              ),
            ),
          );
        },
      ),
    );
  }
}
