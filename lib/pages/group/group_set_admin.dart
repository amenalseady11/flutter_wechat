import 'package:flutter/material.dart';
import 'package:flutter_wechat/apis/apis.dart';
import 'package:flutter_wechat/global/global.dart';
import 'package:flutter_wechat/providers/group/group.dart';
import 'package:flutter_wechat/providers/group/group_list.dart';
import 'package:flutter_wechat/providers/group/group_member.dart';
import 'package:flutter_wechat/util/adapter/adapter.dart';
import 'package:flutter_wechat/util/style/style.dart';
import 'package:flutter_wechat/util/toast/toast.dart';
import 'package:flutter_wechat/widgets/avatar/avatar.dart';
import 'package:flutter_wechat/widgets/mh_text_field/mh_text_field.dart';

class GroupSetAdminPage extends StatefulWidget {
  final String groupId;

  const GroupSetAdminPage({Key key, this.groupId}) : super(key: key);

  @override
  _GroupSetAdminPageState createState() => _GroupSetAdminPageState();
}

class _GroupSetAdminPageState extends State<GroupSetAdminPage> {
  GroupProvider _group;

  TextEditingController _search = TextEditingController();

  List<GroupMemberProvider> _members;

  GroupMemberProvider _self;

  List<String> _selects = [];

  @override
  void initState() {
    super.initState();
    var glpm = GroupListProvider.of(context, listen: false).map;
    this._group = glpm[widget.groupId] ?? GroupProvider();
    this._members = List.from(_group.members);
    this._self = this._members.firstWhere(
        (d) => d.friendId == global.profile.friendId,
        orElse: () => GroupMemberProvider());
  }

  get members {
    _members..sort((d1, d2) => d2.roleSort.compareTo(d1.roleSort));
    var members = _members.where((d) => d.name.contains(_search.text)).toList();
    return members;
  }

  @override
  void dispose() {
    super.dispose();
    Future.microtask(() async {
      if (_selects.length == 0) return;
      _group.serialize();
      var rsp = await toGetGroup(groupId: widget.groupId);
      if (!rsp.success) Toast.showToast(context, message: rsp.message);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(ew(80)),
        child: AppBar(
          titleSpacing: -ew(20),
          centerTitle: false,
          title: Text("设置管理员"),
        ),
      ),
      body: _buildChild(context),
    );
  }

  _buildChild(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: <Widget>[
          _buildSearch(context),
          ListView.builder(
            shrinkWrap: true,
            itemCount: members.length > 0 ? members.length : 1,
            itemBuilder: (BuildContext context, int index) {
              return _buildListItem(
                  context, members.length <= index ? null : members[index]);
            },
          ),
        ],
      ),
    );
  }

  _buildSearch(BuildContext context) {
    return Container(
      width: double.maxFinite,
      padding: EdgeInsets.symmetric(horizontal: ew(40)),
      decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Style.pDividerColor))),
      child: Row(
        children: <Widget>[
          Text("🔍", style: TextStyle(fontSize: sp(36))),
          SizedBox(width: ew(20)),
          Expanded(
            child: MHTextField(
              controller: _search,
              maxLength: 20,
              clearButtonMode: MHTextFieldWidgetMode.never,
              onChanged: (value) {
                if (mounted) setState(() {});
              },
            ),
          ),
        ],
      ),
    );
  }

  _buildListItem(BuildContext context, GroupMemberProvider member) {
    if (member?.friendId == null || member.friendId.isEmpty) {
      return Container(
        color: Style.pBackgroundColor,
        height: ew(200),
        child: Center(
          child: Text.rich(
            TextSpan(children: [
              TextSpan(text: "没有找到"),
              TextSpan(
                  text: "\"${_search.text}\"",
                  style: TextStyle(color: Style.pTintColor)),
              TextSpan(text: "相关结果"),
            ]),
            style: TextStyle(fontSize: sp(28)),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        ListTile(
          leading: CAvatar(avatar: member.avatar, size: ew(72), radius: ew(8)),
          title: Text(member.name),
          trailing: getTrailing(context, member) ??
              Container(
                padding: EdgeInsets.symmetric(vertical: ew(24)),
                constraints: BoxConstraints(minWidth: ew(140)),
                child: RaisedButton(
                  color: !member.isAdmin ? Colors.redAccent : Style.pTintColor,
                  textColor: Colors.white,
                  elevation: 0.0,
                  child: member.isAdmin ? Text("管理员") : Text("成员"),
                  onPressed: () => _setAdmin(context, member),
                ),
              ),
        ),
        Divider(height: ew(1), color: Style.pDividerColor),
      ],
    );
  }

  getTrailing(BuildContext context, GroupMemberProvider member) {
    List<String> rst = [];

    if (member.isMaster) {
      rst.add("群主");
    } else if (!_self.isAdmin) {
      rst.add(member.isAdmin ? '管理员' : '成员');
    } else if (_self.isAdmin && !_self.isMaster) {
      rst.add("管理员");
    }

    if (rst.isNotEmpty)
      return Container(
          padding: EdgeInsets.symmetric(vertical: ew(24)),
          constraints: BoxConstraints(minWidth: ew(140)),
          child: RaisedButton(
            disabledTextColor: Colors.white70,
            disabledElevation: 0,
            child: Text(rst.join("/")),
            onPressed: null,
          ));
    return null;
  }

  _setAdmin(BuildContext context, GroupMemberProvider member) async {
    int role =
        member.isAdmin ? GroupMemberRoles.member : GroupMemberRoles.admin;
    var rsp = await toSetGroupMemberRole(
        groupId: _group.groupId, friendId: member.friendId, role: role);
    debugPrint(_group.toJson().toString());
    debugPrint(_group.self.toJson().toString());
    if (!rsp.success) return Toast.showToast(context, message: rsp.message);
    member.role = role;
    await _group.serialize(forceUpdate: true);
    if (mounted) setState(() {});
  }
}
