import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_wechat/providers/chat/chat.dart';
import 'package:flutter_wechat/routers/routers.dart';
import 'package:flutter_wechat/util/adapter/adapter.dart';
import 'package:provider/provider.dart';

import 'app_bar_loading.dart';

class ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  @override
  Widget build(BuildContext context) {
    return AppBar(
      centerTitle: false,
      titleSpacing: -ew(20),
      elevation: 0.0,
      title: Selector<ChatProvider, String>(
        selector: (context, chat) {
          if (chat.sourceType == 0) return chat.contact?.name ?? "";
          return "${chat.group?.name ?? ""}(${chat.group?.members?.length ?? 0})";
        },
        builder: (context, title, child) {
          return Row(children: <Widget>[
            Text(
              title,
              style: TextStyle(fontSize: sp(32)),
            ),
            child
          ]);
        },
        child: AppBarLoading(chat: ChatProvider.of(context, listen: false)),
      ),
      actions: <Widget>[
        IconButton(
          icon: new SvgPicture.asset(
            'assets/images/contacts/icons_outlined_more.svg',
            color: Color(0xFF333333),
          ),
          onPressed: () {
            var chat = ChatProvider.of(context, listen: false);
            if (chat.group != null)
              return Routers.navigateTo(
                  context, Routers.chatSetGroup + "?groupId=${chat.sourceId}");

            Routers.navigateTo(
                context, Routers.chatSetContact + "?friendId=${chat.sourceId}");
          },
        )
      ],
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(ew(80));
}
