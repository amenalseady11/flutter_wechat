import 'package:flutter/material.dart';
import 'package:flutter_wechat/global/global.dart';
import 'package:flutter_wechat/providers/chat/chat.dart';
import 'package:flutter_wechat/providers/chat/chat_list.dart';
import 'package:flutter_wechat/providers/group/group.dart';
import 'package:flutter_wechat/providers/group/group_list.dart';
import 'package:flutter_wechat/routers/routers.dart';
import 'package:flutter_wechat/socket/socket.dart';
import 'package:flutter_wechat/util/adapter/adapter.dart';
import 'package:flutter_wechat/util/style/style.dart';
import 'package:flutter_wechat/widgets/avatar/group_avatar.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class GroupsPage extends StatefulWidget {
  @override
  _GroupsPageState createState() => _GroupsPageState();
}

class _GroupsPageState extends State<GroupsPage> {
  var _refreshController = RefreshController(initialRefresh: false);
  @override
  void initState() {
    super.initState();
    if (GroupListProvider.of(context, listen: false).groups.isEmpty) {
      _refreshController.requestRefresh();
    }
  }

  _onRefresh() async {
    var glp = GroupListProvider.of(context, listen: false);
    var bool = await glp.remoteUpdate(context);
    bool
        ? _refreshController.refreshCompleted()
        : _refreshController.refreshFailed();
    var chats = ChatListProvider.of(context, listen: false).map;
    for (var group in glp.groups) {
      ChatProvider chat = chats[group.groupId];
      if (chat == null) {
        chat = ChatProvider(
          profileId: global.profile.profileId,
          sourceType: ChatSourceType.group,
          sourceId: group.groupId,
          latestUpdateTime: DateTime(2020, 2, 1),
          visible: false,
        );
        await chat.serialize(forceUpdate: true);
        Provider.of<ChatListProvider>(context, listen: false).chats.add(chat);
      }
      chat.group = group;
      socket.create(
          private: false, sourceId: group.groupId, getOffset: () => chat.group);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(ew(80)),
        child: AppBar(
          title: Text('群聊'),
          centerTitle: false,
          titleSpacing: -ew(20),
          actions: <Widget>[
            FlatButton(
              child: Text('发起群聊',
                  style:
                      TextStyle(fontSize: sp(28), fontWeight: FontWeight.w400)),
              onPressed: () => Routers.navigateTo(
                  context, Routers.groupAddMember,
                  replace: false),
            ),
          ],
        ),
      ),
      body: Consumer<GroupListProvider>(
        builder: (BuildContext context, GroupListProvider glp, Widget child) {
          return SmartRefresher(
            controller: _refreshController,
            onRefresh: _onRefresh,
            header: WaterDropHeader(waterDropColor: Style.pTintColor),
            child: ListView.builder(
                shrinkWrap: true,
                itemCount: glp.groups.length,
                itemBuilder: (context, index) =>
                    _buildItemChild(context, glp.groups[index])),
          );
        },
      ),
    );
  }

  _buildItemChild(BuildContext context, GroupProvider group) {
    return Column(
      children: <Widget>[
        ListTile(
          contentPadding:
              EdgeInsets.symmetric(vertical: ew(16), horizontal: ew(30)),
          leading: GroupAvatar(avatars: group.avatars),
          title: Text(group.name + "(${group.members.length})"),
          trailing: Image.asset("assets/images/icons/tableview_arrow_8x13.png",
              width: ew(16), height: ew(26)),
          onTap: () {
            Routers.navigateTo(context,
                Routers.chat + "?sourceType=1&sourceId=${group.groupId}");
          },
        ),
        Divider(height: ew(1), color: Style.pDividerColor),
      ],
    );
  }
}
