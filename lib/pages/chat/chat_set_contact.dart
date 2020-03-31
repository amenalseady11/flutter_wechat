import 'package:flutter/material.dart';
import 'package:flutter_wechat/providers/chat/chat.dart';
import 'package:flutter_wechat/providers/chat/chat_list.dart';
import 'package:flutter_wechat/providers/contact/contact.dart';
import 'package:flutter_wechat/util/adapter/adapter.dart';
import 'package:flutter_wechat/util/dialog/dialog.dart';
import 'package:flutter_wechat/util/style/style.dart';
import 'package:flutter_wechat/widgets/avatar/avatar.dart';
import 'package:photo_view/photo_view.dart';

class ChatSetContactPage extends StatefulWidget {
  final String friendId;

  const ChatSetContactPage({Key key, this.friendId}) : super(key: key);

  @override
  _ChatSetContactPageState createState() => _ChatSetContactPageState();
}

class _ChatSetContactPageState extends State<ChatSetContactPage> {
  ChatProvider _chat;
  get chat => _chat;
  ContactProvider _contact;
  get contact => _contact;

  @override
  void initState() {
    super.initState();
    _chat = ChatListProvider.of(context, listen: false).map[widget.friendId] ??
        ChatProvider(
            sourceType: 0,
            sourceId: widget.friendId,
            latestUpdateTime: DateTime.now());
    _contact = _chat.contact ??
        (ContactProvider.fromJson({})..friendId = widget.friendId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(ew(80)),
        child: AppBar(
            title: Text("聊天信息", style: TextStyle(fontSize: sp(34))),
            centerTitle: false,
            titleSpacing: -ew(20)),
      ),
      body: ListView(shrinkWrap: true, children: <Widget>[
        _buildHead(context),
        _buildPane1(context),
        _buildPane2(context),
      ]),
    );
  }

  _buildHead(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: ew(20), vertical: ew(20)),
      child: Column(children: <Widget>[
        Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              CAvatar(
                heroTag: "avatar",
                avatar: contact.avatar,
                size: ew(120),
                radius: ew(8),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) {
                      return Scaffold(
                        appBar: AppBar(
                          backgroundColor: Colors.black,
                          brightness: Brightness.dark,
                          iconTheme: IconThemeData(color: Colors.white),
                        ),
                        body: PhotoView(
                          imageProvider: NetworkImage(contact.avatar),
                          minScale: 1.0,
                          heroAttributes:
                              const PhotoViewHeroAttributes(tag: "avatar"),
                        ),
                      );
                    }),
                  );
                },
              ),
              SizedBox(width: ew(40)),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SizedBox(height: ew(10)),
                  Text(contact.name,
                      style:
                          TextStyle(color: Style.pTextColor, fontSize: sp(38))),
                  SizedBox(height: ew(8)),
                  Text(
                    "手机号：${contact.mobile}",
                    style: TextStyle(color: Style.sTextColor, fontSize: sp(26)),
                  )
                ],
              ),
            ]),
      ]),
    );
  }

  _buildPane1(BuildContext context) {
    return Column(children: <Widget>[
      Container(height: ew(16), color: Style.pBackgroundColor),
      SwitchListTile(
        value: _chat.mute,
        activeColor: Style.pTintColor,
        title: Text("消息免打扰",
            style: TextStyle(color: Style.tTextColor, fontSize: sp(31))),
        onChanged: (_) => _setMuteChat(context, _),
      ),
      Divider(height: ew(1), color: Style.pDividerColor),
      SwitchListTile(
        value: _chat.top,
        activeColor: Style.pTintColor,
        title: Text("置顶聊天",
            style: TextStyle(color: Style.tTextColor, fontSize: sp(31))),
        onChanged: (_) => _setTopChat(context, _),
      ),
    ]);
  }

  _buildPane2(BuildContext context) {
    return Column(children: <Widget>[
      Container(height: ew(16), color: Style.pBackgroundColor),
      ListTile(
          title: Text('清空聊天记录',
              style: TextStyle(color: Style.tTextColor, fontSize: sp(31))),
          onTap: () => _clearChatRecords(context)),
//      Divider(height: ew(1), color: Style.pDividerColor),
      Container(height: ew(16), color: Style.pBackgroundColor),
    ]);
  }

  _setMuteChat(BuildContext context, bool mute) {
    _chat.mute = !_chat.mute;
    _chat.serialize();
    if (mounted) setState(() {});
  }

  _setTopChat(BuildContext context, bool top) {
    _chat.top = !_chat.top;
    if (_chat.top) _chat.visible = true;
    _chat.serialize(forceUpdate: true);
    ChatListProvider.of(context, listen: false).sort(forceUpdate: true);
    if (mounted) setState(() {});
  }

  _clearChatRecords(BuildContext context) async {
    if (!await confirm(context,
        content: "确定删除和${contact.name}的聊天记录吗？", okText: "清空")) return;
    await ChatListProvider.of(context, listen: false).delete(_chat.sourceId);
  }
}
