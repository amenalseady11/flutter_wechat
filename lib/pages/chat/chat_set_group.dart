import 'package:flutter/material.dart';
import 'package:flutter_wechat/apis/apis.dart';
import 'package:flutter_wechat/global/global.dart';
import 'package:flutter_wechat/providers/chat/chat.dart';
import 'package:flutter_wechat/providers/chat/chat_list.dart';
import 'package:flutter_wechat/providers/group/group.dart';
import 'package:flutter_wechat/providers/group/group_list.dart';
import 'package:flutter_wechat/providers/group/group_member.dart';
import 'package:flutter_wechat/routers/routers.dart';
import 'package:flutter_wechat/util/adapter/adapter.dart';
import 'package:flutter_wechat/util/dialog/dialog.dart';
import 'package:flutter_wechat/util/style/style.dart';
import 'package:flutter_wechat/util/toast/toast.dart';
import 'package:flutter_wechat/widgets/avatar/avatar.dart';

class ChatSetGroupPage extends StatefulWidget {
  final String groupId;

  const ChatSetGroupPage({Key key, this.groupId}) : super(key: key);

  @override
  _ChatSetGroupPageState createState() => _ChatSetGroupPageState();
}

class _ChatSetGroupPageState extends State<ChatSetGroupPage> {
  GroupProvider _group;
  ChatProvider _chat;

  GroupMemberProvider _self;

  get isMaster => _group.isMaster || _self.isMaster;
  get isAdmin => _group.isMaster || _self.isAdmin;

  @override
  void initState() {
    super.initState();
    var glp = GroupListProvider.of(context, listen: false);
    _group = glp.map[widget.groupId] ?? GroupProvider(name: "群聊");
    _self = _group.members.firstWhere(
        (d) => d.friendId == global.profile.friendId,
        orElse: () => GroupMemberProvider(
            groupId: _group.groupId, friendId: global.profile.friendId));

    var clp = ChatListProvider.of(context, listen: false);
    _chat = clp.map[_group.groupId] ??
        ChatProvider(
            sourceType: 1,
            sourceId: _group.groupId,
            profileId: global.profile.profileId,
            latestUpdateTime: DateTime.now());
    if (_chat.serializeId == null) {
      _chat.serialize();
      clp.chats.add(_chat);
      clp.forceUpdate();
    }

    Future.microtask(() async {
      _group = _chat.group = (await _group.remoteUpdate(context)) ?? _group;
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(ew(80)),
        child: AppBar(
          backgroundColor: Colors.white,
          title: Text(
            '${_group.name}(${_group.members.length})',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          centerTitle: false,
          titleSpacing: -ew(20),
        ),
      ),
      body: ListView(
        shrinkWrap: true,
        children: <Widget>[
          _buildMembers(context),
          _buildPane1(context),
          _buildPane2(context),
          Container(height: ew(16), color: Style.pBackgroundColor),
          ListTile(
              title: Text('清空聊天记录',
                  style: TextStyle(fontSize: sp(31), color: Style.tTextColor)),
              onTap: () => _clearChatRecords(context)),
          Container(height: ew(16), color: Style.pBackgroundColor),
          _buildPane3(context),
          Container(height: ew(16), color: Style.pBackgroundColor),
        ],
      ),
    );
  }

  _buildMembers(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: ew(20), vertical: ew(20)),
      child: GridView.builder(
          itemCount: _group.members.length + (isAdmin ? 2 : 0),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            //横轴元素个数
            crossAxisCount: 5,
            //纵轴间距
            mainAxisSpacing: ew(10),
            //横轴间距
            crossAxisSpacing: ew(10),
            //子组件宽高长度比例
            childAspectRatio: 1.0,
          ),
          itemBuilder: (BuildContext context, int index) {
            var len = _group.members.length;
            // 添加按钮
            if (index == len) {
              return _buildDoMemberButton(
                icon: Icons.add,
                bgColor: Style.pTintColor,
                iconColor: Colors.white,
                onPressed: () {
                  return Routers.navigateTo(context,
                      Routers.groupAddMember + "?groupId=${_group.groupId}");
                },
              );
            }

            // 删除按钮
            if (index == len + 1) {
              return _buildDoMemberButton(
                  icon: Icons.remove,
                  bgColor: Colors.redAccent,
                  iconColor: Colors.white,
                  onPressed: () {
                    return Routers.navigateTo(context,
                        Routers.groupDelMember + "?groupId=${_group.groupId}");
                  });
            }

            var member = _group.members[index];
            //Widget Function(BuildContext context, int index)
            return InkWell(
              onTap: () {
                Routers.navigateTo(
                    context,
                    Routers.contact +
                        "?groupId=${member.groupId}&friendId=${member.friendId}");
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  CAvatar(
                      avatar: member.avatar ?? "", size: ew(90), radius: ew(8)),
                  SizedBox(height: ew(10)),
                  Text(member.name,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style:
                          TextStyle(color: Style.sTextColor, fontSize: sp(22))),
                ],
              ),
            );
          }),
    );
  }

  _buildDoMemberButton(
      {IconData icon, VoidCallback onPressed, Color bgColor, Color iconColor}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        InkWell(
          onTap: onPressed,
          child: Container(
            width: ew(90),
            height: ew(90),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(ew(6))),
                color: bgColor ?? Style.pBackgroundColor.withOpacity(0.5)),
            child: Icon(icon, size: sp(60), color: iconColor ?? Colors.black54),
          ),
        ),
        SizedBox(height: ew(10)),
        Text("", style: TextStyle(color: Style.sTextColor, fontSize: sp(24))),
      ],
    );
  }

  _buildPane1(BuildContext context) {
    var children = [
      Container(height: ew(16), color: Style.pBackgroundColor),
      ListTile(
        leading: Container(
            width: ew(160),
            child: Text('群聊名称',
                style: TextStyle(fontSize: sp(32), color: Style.tTextColor))),
        title: Text(
          _group.name ?? "",
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
              fontSize: sp(31),
              color: Style.sTextColor,
              fontWeight: FontWeight.w300),
        ),
        trailing: !isAdmin
            ? null
            : Image.asset("assets/images/icons/tableview_arrow_8x13.png",
                width: ew(16), height: ew(26)),
        onTap: !isAdmin ? null : () => _editGroupName(context),
      ),
//        Divider(height: ew(1), color: Style.pDividerColor),
//        ListTile(
//          leading: Container(
//              width: ew(160),
//              child: Text('群二维码', style: TextStyle(fontSize: sp(31)))),
//          trailing: Image.asset("assets/images/icons/tableview_arrow_8x13.png",
//              width: ew(16), height: ew(26)),
//          onTap: () {},
//        ),
      Divider(height: ew(1), color: Style.pDividerColor),
      ListTile(
        title: Container(
            width: ew(160),
            padding: EdgeInsets.only(top: ew(20)),
            child: Text('群聊公告',
                style: TextStyle(fontSize: sp(31), color: Style.tTextColor))),
        subtitle: Container(
          padding: EdgeInsets.symmetric(vertical: ew(10)),
          constraints: BoxConstraints(minHeight: ew(80)),
          child: Text(_group.announcement ?? "",
              style: TextStyle(color: Style.sTextColor, fontSize: sp(24))),
        ),
        trailing: !isAdmin
            ? null
            : Image.asset("assets/images/icons/tableview_arrow_8x13.png",
                width: ew(16), height: ew(26)),
        onTap: !isAdmin ? null : () => _editGroupAnnouncement(context),
      ),
    ];

    children.addAll([
      Container(height: ew(16), color: Style.pBackgroundColor),
      ListTile(
        title: Container(
            width: ew(160),
            child: Text('群主及管理员',
                style: TextStyle(fontSize: sp(31), color: Style.tTextColor))),
        trailing: Image.asset("assets/images/icons/tableview_arrow_8x13.png",
            width: ew(16), height: ew(26)),
        onTap: () => _setGroupAdmin(context),
      ),
      Divider(height: ew(1), color: Style.pDividerColor),
      SwitchListTile(
        value: _group.forbidden == GroupForbiddenStatus.forbidden,
        activeColor: Style.pTintColor,
        title: Text("全体禁言",
            style: TextStyle(fontSize: sp(31), color: Style.tTextColor)),
        onChanged: (_) => _setGroupForbidden(context),
      ),
    ]);

    return Column(
      children: children,
    );
  }

  _buildPane2(BuildContext context) {
    return Column(children: <Widget>[
      Container(height: ew(16), color: Style.pBackgroundColor),
//      SwitchListTile(
//        value: _chat.mute,
//        activeColor: Style.pTintColor,
//        title: Text("消息免打扰", style: TextStyle(fontSize: sp(31))),
//        onChanged: (_) => _setMuteChat(context, _),
//      ),
//      Divider(height: ew(1), color: Style.pDividerColor),
      SwitchListTile(
        value: _chat.top,
        activeColor: Style.pTintColor,
        title: Text("置顶聊天", style: TextStyle(fontSize: sp(31))),
        onChanged: (_) => _setTopChat(context, _),
      ),
      Divider(height: ew(1), color: Style.pDividerColor),
      ListTile(
        title: Text("我的本群的昵称",
            style: TextStyle(fontSize: sp(31), color: Style.tTextColor)),
        trailing: Container(
          width: ew(400),
          child:
              Row(mainAxisAlignment: MainAxisAlignment.end, children: <Widget>[
            Text(_self.name,
                style: TextStyle(color: Style.sTextColor, fontSize: sp(31)),
                overflow: TextOverflow.ellipsis),
            SizedBox(width: ew(20)),
//            Image.asset("assets/images/icons/tableview_arrow_8x13.png",
//                width: ew(16), height: ew(26))
          ]),
        ),
      ),
    ]);
  }

  _buildPane3(BuildContext context) {
    if (isMaster) {
      return ListTile(
        title: Text('删除并退出',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.red, fontSize: sp(31))),
        onTap: () => _dismissGroup(context),
      );
    }

    if (isAdmin) {
      return ListTile(
        title: Text('退出群聊',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.red, fontSize: sp(31))),
        onTap: () => _signOutGroup(context),
      );
    }
    return Container();
  }

  _dismissGroup(BuildContext context) async {
    var rsp = await toDismissGroup(groupId: _group.groupId);
    if (!rsp.success) return Toast.showToast(context, message: rsp.message);
    GroupListProvider.of(context, listen: false).groups.remove(_group);
    await ChatListProvider.of(context, listen: false)
        .delete(_group.groupId, real: true);
    Routers.navigateTo(context, Routers.homeChats,
        transition: TransitionType.fadeIn, clearStack: true);
    Toast.showToast(context, message: "解散成功");
  }

  _signOutGroup(BuildContext context) async {
    var rsp =
        await toSignOutGroup(groupId: _group.groupId, friendId: _self.friendId);
    if (!rsp.success) return Toast.showToast(context, message: rsp.message);
    GroupListProvider.of(context, listen: false).groups.remove(_group);
    await ChatListProvider.of(context, listen: false)
        .delete(_group.groupId, real: true);
    Routers.navigateTo(context, Routers.homeChats,
        transition: TransitionType.fadeIn, clearStack: true);
    Toast.showToast(context, message: "退出成功");
  }

  _editGroupName(BuildContext context) async {
    if (!isAdmin) {
      return Toast.showToast(context, message: "只有群主及管理员可以编辑群名称");
    }
    var rst = await Routers.navigateTo(context,
        Routers.groupSetName + "?name=${Uri.encodeComponent(_group.name)}");

    if (rst is! String || rst.isEmpty) return;
    if (rst == _self.name) return;

    var rsp = await toUpdateGroup(name: rst, groupId: _group.groupId);
    if (!rsp.success) return Toast.showToast(context, message: rsp.message);
    _group.name = _chat.group.name = rst;
    _group.serialize(forceUpdate: true);
    _chat.forceUpdate();
//    ChatListProvider.of(context, listen: false).forceUpdate();
    if (mounted) setState(() {});
  }

  _editGroupAnnouncement(BuildContext context) async {
    if (!isAdmin) {
      return Toast.showToast(context, message: "只有群主及管理员可以编辑群公告");
    }
    var rst = await Routers.navigateTo(
        context,
        Routers.groupSetAnnouncement +
            "?announcement=${Uri.encodeComponent(_group.announcement)}");

    if (rst is! String || rst.isEmpty) return;
    if (rst == _self.name) return;

    var rsp = await toUpdateGroup(announcement: rst, groupId: _group.groupId);
    if (!rsp.success) return Toast.showToast(context, message: rsp.message);
    _group.announcement = _chat.group.announcement = rst;
    _group.serialize(forceUpdate: true);
    _chat.forceUpdate();
    if (mounted) setState(() {});
  }

  _clearChatRecords(BuildContext context) async {
    if (!await confirm(context, content: "确定删除群的聊天记录吗？", okText: "清空")) return;
    await ChatListProvider.of(context, listen: false).delete(_chat.sourceId);
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

  _setGroupAdmin(BuildContext context) {
    Routers.navigateTo(
        context, Routers.groupSetAdmin + "?groupId=${_group.groupId}");
  }

  _setGroupForbidden(BuildContext context) async {
    if (!isMaster) return Toast.showToast(context, message: "只有群主可以设置禁言");
//    Routers.navigateTo(
//        context, Routers.groupSetForbidden + "?groupId=${_group.groupId}");
    var forbidden = (_self.forbidden + 1) % 2;
    var rsp = await toSetGroupForbidden(
        groupId: _group.groupId, forbidden: forbidden);
    if (!rsp.success) Toast.showToast(context, message: rsp.message);
    _self.forbidden = forbidden;
    await _group.serialize();
    if (mounted) setState(() {});
  }
}
