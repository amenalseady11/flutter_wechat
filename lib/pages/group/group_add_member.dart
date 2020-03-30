import 'package:azlistview/azlistview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_wechat/apis/apis.dart';
import 'package:flutter_wechat/global/global.dart';
import 'package:flutter_wechat/providers/contact/contact.dart';
import 'package:flutter_wechat/providers/contact/contact_list.dart';
import 'package:flutter_wechat/providers/group/group.dart';
import 'package:flutter_wechat/providers/group/group_list.dart';
import 'package:flutter_wechat/routers/routers.dart';
import 'package:flutter_wechat/socket/socket.dart';
import 'package:flutter_wechat/util/adapter/adapter.dart';
import 'package:flutter_wechat/util/style/style.dart';
import 'package:flutter_wechat/util/toast/toast.dart';
import 'package:flutter_wechat/widgets/avatar/avatar.dart';
import 'package:flutter_wechat/widgets/mh_text_field/mh_text_field.dart';

class GroupAddMemberPage extends StatefulWidget {
  final String groupId;

  const GroupAddMemberPage({Key key, this.groupId}) : super(key: key);
  @override
  _GroupAddMemberPageState createState() => _GroupAddMemberPageState();
}

class _GroupAddMemberPageState extends State<GroupAddMemberPage> {
  GroupProvider _group;

  List<String> _selects = [];
  List<String> _selectsPrev = [];

  String _susTag = "";

  TextEditingController _search = TextEditingController();

  Map<String, List<ContactProvider>> _map = {};

  @override
  void initState() {
    super.initState();
    if (widget.groupId != null && widget.groupId.isNotEmpty) {
      var glpm = GroupListProvider.of(context, listen: false).map;
      if (glpm.containsKey(widget.groupId)) _group = glpm[widget.groupId];
    }

    if (_group == null)
      _group = GroupProvider(profileId: global.profile.profileId);

    _selectsPrev = _group.members.map((d) => d.friendId).toList();
  }

  get contacts {
    if (_map.containsKey(_search.text)) return _map[_search.text];
    var contacts = ContactListProvider.of(context, listen: false).contacts;
    if (_search.text.isEmpty) return contacts;
    contacts = contacts.where((d) => d.name.contains(_search.text)).toList();
    _map.putIfAbsent(_search.text, () => contacts);
    return contacts;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(ew(80)),
        child: AppBar(
          titleSpacing: -ew(20),
          centerTitle: false,
          title: _group.groupId == null ? Text("发起群聊") : Text("选择成员"),
          actions: <Widget>[
            _buildSaveBtn(context),
          ],
        ),
      ),
      body: _buildChild(context),
    );
  }

  _buildSaveBtn(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(right: ew(20)),
      padding: EdgeInsets.symmetric(vertical: ew(10), horizontal: ew(0)),
      width: ew(160),
      child: RaisedButton(
        color: Style.pTintColor,
        textColor: Colors.white,
        disabledColor: Colors.grey.withOpacity(0.7),
        disabledTextColor: Colors.white,
        elevation: 0,
        clipBehavior: Clip.hardEdge,
        child: Text("确定" + (_selects.length > 0 ? "(${_selects.length})" : ""),
            style: TextStyle(fontSize: sp(28))),
        onPressed: _selects.length == 0 ? null : () => _save(context),
      ),
    );
  }

  _buildChild(BuildContext context) {
    return Container(
      width: double.maxFinite,
      height: double.maxFinite,
      child: AzListView(
        data: contacts.length > 0 ? contacts : [ContactProvider.fromJson({})],
        showIndexHint: false,
        isUseRealIndex: false,
        header: _buildAZLVHeader(context),
        itemBuilder: (context, model) => _buildAZLVItem(context, model),
        itemHeight: ew(120).toInt(),
        suspensionWidget: Container(
            width: double.maxFinite,
            padding: EdgeInsets.symmetric(horizontal: ew(55), vertical: ew(10)),
            color: Style.pBackgroundColor,
            child: Text(_susTag,
                style: TextStyle(color: Style.pTintColor, fontSize: sp(30)))),
        onSusTagChanged: (tag) {
          _susTag = tag;
          if (mounted) setState(() {});
        },
      ),
    );
  }

  _buildAZLVHeader(BuildContext context) {
    return AzListViewHeader(
      height: ew(100).toInt(),
      builder: (context) {
        return Container(
          width: double.maxFinite,
          padding: EdgeInsets.symmetric(horizontal: ew(40)),
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
      },
    );
  }

  Widget _buildAZLVItem(BuildContext context, ContactProvider contact) {
    if (contact.friendId == null || contact.friendId.isEmpty) {
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
        Offstage(
          offstage: contact.isShowSuspension != true,
          child: Container(
              width: double.maxFinite,
              padding:
                  EdgeInsets.symmetric(horizontal: ew(55), vertical: ew(10)),
              color: Style.pBackgroundColor,
              child: Text(contact.getSuspensionTag(),
                  style: TextStyle(color: Colors.black54, fontSize: sp(30)))),
        ),
        CheckboxListTile(
          activeColor: Style.pTintColor,
          selected: false,
          value: _selectsPrev.contains(contact.friendId) ||
              _selects.contains(contact.friendId),
          controlAffinity: ListTileControlAffinity.leading,
          onChanged: _selectsPrev.contains(contact.friendId)
              ? null
              : (value) {
                  _selects.contains(contact.friendId)
                      ? _selects.remove(contact.friendId)
                      : _selects.add(contact.friendId);
                  if (mounted) setState(() {});
                },
          title: Container(
            padding: EdgeInsets.symmetric(vertical: ew(10)),
            child: Row(children: <Widget>[
              CAvatar(avatar: contact.avatar, size: ew(72), radius: ew(8)),
              SizedBox(width: ew(20)),
              Text(contact.name)
            ]),
          ),
        ),
        Divider(height: ew(1), color: Style.pDividerColor),
      ],
    );
  }

  _save(BuildContext context) async {
    if (_selects.length == 0) return;

    // 新增
    if (_group.groupId == null || _group.groupId.isEmpty) {
      var rsp = await toAddGroup(friendIds: _selects);
      if (!rsp.success) return Toast.showToast(context, message: rsp.message);

      var group = await GroupListProvider.of(context, listen: false)
          .saveGroupByMap(rsp.body);

      socket.create(
          private: false, sourceId: group.groupId, getOffset: () => 0);

      /// 这个位置最好返回群组信息
      /// 直接进入群聊聊天界面
      Routers.navigateTo(
          context, Routers.chat + "?sourceType=1&sourceId=${group.groupId}",
          replace: true);

      Toast.showToast(context, message: "创建成功");
      return;
    }

    var rsp =
        await toInviteJoinGroup(groupId: _group.groupId, friendIds: _selects);
    if (!rsp.success) return Toast.showToast(context, message: rsp.message);
    await _group.remoteUpdate(context);

    /// 这个位置最好返回群组信息
    /// 直接进入群聊聊天界面
    Routers.navigateTo(
        context, Routers.chat + "?sourceType=1&sourceId=${_group.groupId}",
        replace: true);
    Toast.showToast(context, message: "邀请成功");
  }
}
