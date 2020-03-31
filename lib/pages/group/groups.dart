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
    Future.microtask(() {
      if (GroupListProvider.of(context, listen: false).groups.isEmpty) {
        _refreshController.requestRefresh();
      }
    });
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
      if (group.status != GroupStatus.joined) continue;
      socket.create(
          private: false,
          sourceId: group.groupId,
          getOffset: () => chat.offset);
    }
  }

  @override
  Widget build(BuildContext context) {
    var prevStr = "";
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(ew(80)),
        child: AppBar(
          title: Text('群聊',
              style: TextStyle(fontSize: sp(34), color: Style.tTextColor)),
          centerTitle: false,
          titleSpacing: -ew(20),
          actions: <Widget>[
            FlatButton(
              child: Text('发起群聊',
                  style:
                      TextStyle(fontSize: sp(31), fontWeight: FontWeight.w400)),
              onPressed: () => Routers.navigateTo(
                  context, Routers.groupAddMember,
                  replace: false),
            ),
          ],
        ),
      ),
      body: SmartRefresher(
        controller: _refreshController,
        onRefresh: _onRefresh,
        header: WaterDropHeader(waterDropColor: Style.pTintColor),
        child: Selector<GroupListProvider, List<GroupProvider>>(
          selector: (context, glp) {
            return glp.groups
                .where((d) => d.status == GroupStatus.joined)
                .toList();
          },
          shouldRebuild: (prev, next) {
            var str1 = prevStr;
            var str2 = prevStr =
                next.fold('', (m, d) => m + "|${d.name}:${d.members.length}");
            return str1 != str2;
          },
          builder: (context, groups, child) {
            return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: groups.length,
                itemBuilder: (context, index) {
                  return ChangeNotifierProvider.value(
                      value: groups[index],
                      child: Consumer<GroupProvider>(
                          builder: (context, group, child) {
                        return _buildItemChild(context, group);
                      }));
                });
          },
        ),
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
          title: Text(group.name + "(${group.members.length})",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: sp(34), color: Style.tTextColor)),
          trailing: Image.asset("assets/images/icons/tableview_arrow_8x13.png",
              width: ew(16), height: ew(26)),
          onTap: () async {
            var rst = await Routers.navigateTo(context,
                Routers.chat + "?sourceType=1&sourceId=${group.groupId}");

            if (rst == 'delete') {
              GroupListProvider.of(context, listen: false).groups.remove(group);
              ChatListProvider.of(context, listen: false)
                  .delete(group.groupId, real: true);
              if (mounted) setState(() {});
              _refreshController.requestRefresh();
            }
          },
        ),
        Divider(height: ew(1), color: Style.pDividerColor),
      ],
    );
  }
}
