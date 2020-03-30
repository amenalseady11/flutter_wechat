import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_wechat/providers/chat/chat.dart';
import 'package:flutter_wechat/providers/group/group.dart';
import 'package:flutter_wechat/routers/routers.dart';
import 'package:flutter_wechat/util/adapter/adapter.dart';
import 'package:provider/provider.dart';

import 'app_bar_loading.dart';

class ChatAppBar extends StatefulWidget implements PreferredSizeWidget {
  @override
  Size get preferredSize => Size.fromHeight(ew(80));
  @override
  _ChatAppBarState createState() => _ChatAppBarState();
}

class _ChatAppBarState extends State<ChatAppBar> {
  @override
  Widget build(BuildContext context) {
    return AppBar(
      centerTitle: false,
      titleSpacing: -ew(20),
      elevation: 0.0,
      title: Selector<ChatProvider, String>(
        selector: (context, chat) {
          if (chat.sourceType == 0) return chat.contact?.name ?? "";
          var len = chat.group?.members?.length ?? 0;
          var text = "${chat.group?.name ?? ""}";
          if (len > 0) text += "($len)";
          return text;
        },
        builder: (context, title, child) {
          return Row(children: <Widget>[
            Container(
              constraints: BoxConstraints(maxWidth: ew(500)),
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: sp(32)),
              ),
            ),
            child
          ]);
        },
        child: AppBarLoading(chat: ChatProvider.of(context, listen: false)),
      ),
      actions: <Widget>[
        Consumer<GroupProvider>(
          builder: (context, group, child) {
            if (group != null && group.status != GroupStatus.joined)
              return Text("");
            return IconButton(
              icon: new SvgPicture.asset(
                'assets/images/contacts/icons_outlined_more.svg',
                color: Color(0xFF333333),
              ),
              onPressed: () async {
                var chat = ChatProvider.of(context, listen: false);
                if (chat.group != null) {
                  await Routers.navigateTo(context,
                      Routers.chatSetGroup + "?groupId=${chat.sourceId}");
                  chat.group.remoteUpdate(context);
                  if (mounted) setState(() {});
                  return;
                }

                Routers.navigateTo(context,
                    Routers.chatSetContact + "?friendId=${chat.sourceId}");
              },
            );
          },
        )
      ],
    );
  }
}
