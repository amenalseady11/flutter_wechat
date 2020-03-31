import 'package:flutter/material.dart';
import 'package:flutter_wechat/providers/contact/contact.dart';
import 'package:flutter_wechat/providers/group/group.dart';
import 'package:flutter_wechat/util/adapter/adapter.dart';
import 'package:flutter_wechat/util/style/style.dart';
import 'package:provider/provider.dart';

import 'chat_bottom_bar.dart';

class ChatBottomBarWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Selector2<GroupProvider, ContactProvider, String>(
      selector: (context, group, contact) {
        if (group?.status == GroupStatus.dismiss)
          return "当前群组已解散";
        else if (group?.status == GroupStatus.exited)
          return "你已被踢出群组";
        else if (group?.forbidden == GroupForbiddenStatus.forbidden)
          return "全体禁言";
//              else if (group?.self?.forbidden == GroupForbiddenStatus.forbidden)
//                return "你已被禁言";

        if (contact?.status == ContactStatus.notFriend)
          return "对方不是你好友";
        else if (contact?.black == ContactBlackStatus.black)
          return "黑名单";
        else if (contact?.black == ContactBlackStatus.eachBlack) return "黑名单";

        return null;
      },
      builder: (context, text, child) {
        if (text == null) return ChatBottomBar();
        return Stack(children: <Widget>[
          ChatBottomBar(),
          Opacity(
            opacity: 0.5,
            child: Container(
              color: Colors.grey,
              width: double.maxFinite,
              height: ew(110),
//                    decoration: BoxDecoration(),
            ),
          ),
          Container(
              height: ew(110),
              child: Center(
                  child: Text(text,
                      style: TextStyle(
                          fontSize: ew(32), color: Style.sTextColor)))),
        ]);
      },
    );
  }
}
