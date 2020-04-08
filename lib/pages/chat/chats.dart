import 'package:flutter/material.dart';
import 'package:flutter_wechat/widgets/popup_menu/popup_menu.dart';
import 'package:flutter_wechat/providers/chat/chat.dart';
import 'package:flutter_wechat/providers/chat/chat_list.dart';
import 'package:flutter_wechat/providers/chat_message/chat_message.dart';
import 'package:flutter_wechat/routers/routers.dart';
import 'package:flutter_wechat/util/adapter/adapter.dart';
import 'package:flutter_wechat/util/style/style.dart';
import 'package:flutter_wechat/widgets/avatar/avatar.dart';
import 'package:flutter_wechat/widgets/avatar/group_avatar.dart';
import 'package:provider/provider.dart';
import 'package:common_utils/common_utils.dart';

class ChatsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Selector<ChatListProvider, List<ChatProvider>>(
      selector: (BuildContext context, ChatListProvider clp) {
        return clp.chats.where((d) {
          if (!d.visible) return false;
          if (d.contact != null) return true;
          if (d.group != null) return true;
          return false;
        }).toList(growable: false)
          ..sort((d1, d2) {
            return d2.sortTime.compareTo(d1.sortTime);
          });
      },
      builder: (BuildContext context, List<ChatProvider> chats, Widget child) {
        return ListView.builder(
            shrinkWrap: true,
            physics: ClampingScrollPhysics(),
            itemCount: chats.length,
            itemBuilder: (BuildContext context, int index) {
              return ChangeNotifierProvider.value(
                value: chats[index],
                child: Consumer<ChatProvider>(builder: (context, chat, child) {
                  return _buildChild(context, chat);
                }),
              );
            });
      },
    );
  }

  Widget _buildChild(BuildContext context, ChatProvider chat) {
    Offset offset;
    Widget child = ListTile(
      leading: _buildAvatar(context, chat),
      title: _buildTitle(context, chat),
      subtitle: _buildSubTitle(context, chat),
      trailing: _buildTrailing(context, chat),
      onLongPress: () => _showMenu(context, offset),
      onTap: () => Routers.navigateTo(
          context,
          Routers.chat +
              "?sourceType=${chat.sourceType}&sourceId=${chat.sourceId}"),
    );

    child = Container(
        decoration: BoxDecoration(
            color: chat.top ? Colors.grey.withOpacity(0.1) : Colors.transparent,
            border: Border(
                bottom: BorderSide(
                    width: ew(1),
                    color: Style.pDividerColor.withOpacity(0.1)))),
        child: child);

    return GestureDetector(
        onTapDown: (details) => offset = details.globalPosition, child: child);
  }

  _buildAvatar(BuildContext context, ChatProvider chat) {
    var avatar = chat.isContactChat
        ? CAvatar(avatar: chat.contact.avatar, size: ew(80), radius: ew(8))
        : GroupAvatar(
            avatars: chat.group?.avatars ?? [], size: ew(80), radius: ew(8));

    if (chat.unread <= 0 && !chat.unreadTag)
      return Container(padding: EdgeInsets.all(ew(6)), child: avatar);

    var text;
    var size;
    if (chat.unread > 99)
      text = '99';
    else if (chat.unread > 0)
      text = chat.unread.toString();
    else
      text = "";

    size = chat.unread > 0 ? ew(30) : ew(20);

    return Stack(
      alignment: Alignment.topRight,
      children: <Widget>[
        Container(padding: EdgeInsets.all(ew(6)), child: avatar),
        Positioned(
          child: Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration:
                BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
            child: Text(text ?? "",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: sp(18, allowFontScalingSelf: true))),
          ),
        )
      ],
    );
  }

  _buildTitle(BuildContext context, ChatProvider chat) {
    var text = chat.isContactChat ? chat.contact.name : chat.group?.name;
    return Text(text ?? "",
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: sp(32), color: Style.pTextColor));
  }

  _buildSubTitle(BuildContext context, ChatProvider chat) {
    ChatMessageProvider message = chat.latestMsg;
    var text;
    if (MessageType.urlImg == message?.type)
      text = "[图片]";
    else if (MessageType.urlVoice == message?.type)
      text = "[语音]";
    else
      text = message?.body;

    return Text(text ?? "",
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: sp(24), color: Style.sTextColor));
  }

  _buildTrailing(BuildContext context, ChatProvider chat) {
    var text;
    var now = DateTime.now();
    var date = chat.latestUpdateTime ?? now;
    var difference = now.difference(date);
    if (difference.inDays < 1)
      text = DateUtil.formatDate(date, format: "HH:mm");
    else if (difference.inDays < 2)
      text = "昨天";
    else if (difference.inDays < 7)
      text = DateUtil.getZHWeekDay(date).replaceAll("星期", "周");
    else if (now.year == date.year)
      text = DateUtil.formatDate(date, format: "MM月dd日");
    else
      text = DateUtil.formatDate(date, format: "yyyy年MM月dd日");

    return Text(text,
        style: TextStyle(fontSize: sp(24), color: Style.sTextColor));
  }

  _showMenu(BuildContext context, Offset offset) async {
    if (offset == null) return;
    final RenderBox overlay = Overlay.of(context).context.findRenderObject();
    final RelativeRect position = RelativeRect.fromLTRB(offset.dx, offset.dy,
        overlay.size.width - offset.dx, overlay.size.height - offset.dy);

    var style = TextStyle(fontSize: sp(30));
    var width = ew(220);
    var item = (String key, String title) {
      return MyPopupMenuItem(
          width: width,
          value: key ?? "",
          child: Text(title ?? "", style: style));
    };

    var chat = ChatProvider.of(context, listen: false);
    bool unread = chat.unreadTag || chat.unread > 0;

    var str = await showMenu<String>(
      context: context,
      position: position,
      items: <MyPopupMenuItem<String>>[
        item('set_unread', unread ? "标记已读" : "标记未读"),
        item('set_top', chat.top ? "取消置顶" : "置顶聊天"),
        item('del_chat', '删除该聊天')
      ],
    );

    if (str == "set_unread") {
      chat.unreadTag = !chat.unreadTag;
      await chat.serialize(forceUpdate: true);
      LogUtil.v("chat:" + chat.toJson().toString());
      return;
    }

    if (str == "set_top") {
      chat.top = !chat.top;
      await chat.serialize(forceUpdate: false);
      ChatListProvider.of(context, listen: false).sort(forceUpdate: true);
      LogUtil.v("chat:" + chat.toJson().toString());
    }

    if (str == "del_chat") {
      var clp = ChatListProvider.of(context, listen: false);
      await clp.delete(chat.sourceId, real: false, fix: true);
    }
  }
}
