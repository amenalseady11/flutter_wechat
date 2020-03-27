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

class GroupDelMemberPage extends StatefulWidget {
  final String groupId;

  const GroupDelMemberPage({Key key, this.groupId}) : super(key: key);

  @override
  _GroupDelMemberPageState createState() => _GroupDelMemberPageState();
}

class _GroupDelMemberPageState extends State<GroupDelMemberPage> {
  GroupProvider _group;

  TextEditingController _search = TextEditingController();

  Map<String, List<GroupMemberProvider>> _map = {};

  List<GroupMemberProvider> _members;

  List<String> _selects = [];

  @override
  void initState() {
    super.initState();
    var glpm = GroupListProvider.of(context, listen: false).map;
    this._group = glpm[widget.groupId] ?? GroupProvider();
    this._members = List.from(_group.members);
  }

  get members {
    if (_map.containsKey(_search.text)) return _map[_search.text];
    if (_search.text.isEmpty) return _members;
    var members = _members.where((d) => d.name.contains(_search.text)).toList();
    _map.putIfAbsent(_search.text, () => members);
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
          title: Text("踢出成员"),
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
          trailing: global.profile.profileId == member.friendId
              ? null
              : Container(
                  padding: EdgeInsets.symmetric(vertical: ew(24)),
                  width: ew(140),
                  child: RaisedButton(
                    color: Style.pTintColor,
                    textColor: Colors.white,
                    disabledTextColor: Colors.white60,
                    elevation: 0.0,
                    child: _selects.contains(member.friendId)
                        ? Text("已踢出")
                        : Text("踢出"),
                    onPressed: _selects.contains(member.friendId)
                        ? null
                        : () {
                            _del(member);
                          },
                  ),
                ),
        ),
        Divider(height: ew(1), color: Style.pDividerColor),
      ],
    );
  }

  void _del(GroupMemberProvider member) async {
    var rsp = await toDeleteGroupMember(
        groupId: _group.groupId, friendId: member.friendId);
    if (!rsp.success) return Toast.showToast(context, message: rsp.message);
    _selects.add(member.friendId);
    _group.members.remove(member);
    if (mounted) setState(() {});
  }
}
