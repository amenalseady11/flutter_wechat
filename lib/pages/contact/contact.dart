import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_wechat/apis/apis.dart';
import 'package:flutter_wechat/global/global.dart';
import 'package:flutter_wechat/providers/chat/chat_list.dart';
import 'package:flutter_wechat/providers/contact/contact_list.dart';
import 'package:flutter_wechat/providers/group/group.dart';
import 'package:flutter_wechat/providers/group/group_list.dart';
import 'package:flutter_wechat/providers/profile/profile.dart';
import 'package:flutter_wechat/routers/routers.dart';
import 'package:flutter_wechat/util/adapter/adapter.dart';
import 'package:flutter_wechat/util/dialog/dialog.dart';
import 'package:flutter_wechat/util/style/style.dart';
import 'package:flutter_wechat/util/toast/toast.dart';
import 'package:flutter_wechat/widgets/action_sheet/action_sheet.dart';
import 'package:flutter_wechat/widgets/avatar/avatar.dart';
import 'package:photo_view/photo_view.dart';

class ContactPage extends StatefulWidget {
  const ContactPage({Key key, @required this.data}) : super(key: key);

  factory ContactPage.fromFriend(
    BuildContext context, {
    String groupId,
    @required String friendId,
  }) {
    var json = ContactPage.getConcatJson(context,
        friendId: friendId, groupId: groupId);
    return ContactPage(data: _ContactData(json));
  }

  /// 暂时解决方案，
  /// 没有太多时间写UI, 每个页面都有特殊传参，使用了json,
  /// 因不需要怎么响应式，没有采用provider
  /// 1. 好友详情
  /// 2. 群组成员详情
  /// 3. 添加好友详情
  /// 4. 验证好友详情
  static Map<String, dynamic> getConcatJson(BuildContext context,
      {String groupId, @required String friendId}) {
    Map<String, dynamic> json;
    var glpm = GroupListProvider.of(context, listen: false).map;
    var clpm = ContactListProvider.of(context, listen: false).map;
    if (groupId != null && groupId.isNotEmpty && glpm.containsKey(groupId)) {
      GroupProvider group = glpm[groupId];
      var member = group.members
          .firstWhere((d) => d.friendId == friendId, orElse: () => null);
      if (member != null) {
        json = member.toJson();
        json.putIfAbsent("_isFriend", () => clpm.containsKey(friendId));
        json.putIfAbsent("_relation", () => _ContactRelation.groupMember);
      }
    }

    if (json == null) {
      if (clpm.containsKey(friendId)) {
        var contact = clpm[friendId];
        json = contact.toJson();
        json.putIfAbsent("_relation", () => _ContactRelation.friend);
        json.putIfAbsent("_isFriend", () => true);
      }
    }

    // 临时好友
    if (json == null) {
      var clptm = ContactListProvider.of(context, listen: false).tmpContacts;
      if (clptm.containsKey(friendId)) {
        json = clptm[friendId];
        // 陌生人，添加好友,申请好友
        json.putIfAbsent("_isFriend", () => false);
        if (json.containsKey("ID")) {
          json.putIfAbsent("_relation", () => _ContactRelation.applyFriend);
        } else {
          json.putIfAbsent("_relation", () => _ContactRelation.stranger);
        }
      }
    }

    if (json == null) {
      json = {"friendId": friendId, "groupId": groupId};
      json.putIfAbsent("_isFriend", () => false);
      json.putIfAbsent("_relation", () => _ContactRelation.unknown);
    }

    String str;
    str = json['remark'] as String;
    json.putIfAbsent("_remark", () => str != null && str.isNotEmpty);

    str = json['nickname'] as String;
    json.putIfAbsent("_nickname", () => str != null && str.isNotEmpty);

    str = json['mobile'] as String;
    json.putIfAbsent("_mobile", () => str != null && str.isNotEmpty);

    json.putIfAbsent("_name", () {
      if (json["_remark"] == true) return json["remark"];
      if (json["_nickname"] == true) return json["nickname"];
      if (json["_mobile"] == true) return json["mobile"];
      return "";
    });

//    LogUtil.v("${jsonEncode(json)}");

    return json;
  }

  final _ContactData data;

  @override
  _ContactPageState createState() => _ContactPageState();
}

class _ContactPageState extends State<ContactPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(ew(80)),
        child: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          actions: <Widget>[
            IconButton(
              icon: new SvgPicture.asset(
                'assets/images/contacts/icons_outlined_more.svg',
                color: Color(0xFF333333),
              ),
              onPressed: () {
                return _showActionSheet(context);
              },
            )
          ],
        ),
      ),
      body: Column(
        children: <Widget>[
          _buildHead(context),
          _buildDoAction(context),
          Expanded(child: Container(color: Style.pBackgroundColor))
        ],
      ),
    );
  }

  _buildHead(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: ew(20), vertical: ew(50)),
      child: Column(children: <Widget>[
        Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              CAvatar(
                heroTag: "avatar",
                avatar: widget.data.avatar,
                size: ew(136),
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
                          imageProvider: NetworkImage(widget.data.avatar),
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
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(widget.data.name,
                      style:
                          TextStyle(color: Style.pTextColor, fontSize: sp(38))),
                  SizedBox(height: ew(20)),
                  Text(
                    (widget.data.relation == _ContactRelation.groupMember
                            ? '群'
                            : '') +
                        "昵称：${widget.data.nickname}",
                    style: TextStyle(color: Style.sTextColor, fontSize: sp(26)),
                  ),
                  SizedBox(height: ew(8)),
                  Text(
                    "手机号：${widget.data.mobile}",
                    style: TextStyle(color: Style.sTextColor, fontSize: sp(26)),
                  )
                ],
              ),
            ]),
      ]),
    );
  }

  _buildDoAction(BuildContext context) {
    if (widget.data.isFriend) {
      return _LineButton(
        top: true,
        title: "发送消息",
        icon: "assets/images/contacts/icons_outlined_chats.svg",
        onTap: () {
          Routers.navigateTo(context,
              "${Routers.chat}?sourceType=${widget.data.sourceType}&sourceId=${widget.data.friendId}");
        },
      );
    }

    if (widget.data.friendId == global.profile.profileId) {
      // 不是好友
      return _LineButton(
        top: true,
        title: "发送消息(当前用户)",
        color: Colors.grey,
        icon: "assets/images/contacts/icons_outlined_chats.svg",
      );
    }

    // 不是好友
    return _LineButton(
      top: true,
      title: "添加到联系人",
      icon: "assets/images/contacts/icons_outlined_addfriends.svg",
      onTap: () {
        Routers.navigateTo(context,
            "${Routers.addContactApply}?friendId=${widget.data.friendId}");
      },
    );
  }

  void _showActionSheet(BuildContext context) async {
    Completer<String> completer = new Completer();

    List<Widget> actions = [];

    if (widget.data.relation == _ContactRelation.groupMember) {
      var glp = GroupListProvider.of(context, listen: false);
      var group = glp.map[widget.data.groupId];
      if (group.self.isAdmin)
        actions.add(ActionSheetAction(
          child: Text('设置群昵称'),
          onPressed: () {
            Navigator.of(context).pop();
            completer.complete("set_group_remark");
          },
        ));
    }

    if (widget.data.isFriend) {
      actions.add(ActionSheetAction(
        child: Text('设置朋友备注'),
        onPressed: () {
          Navigator.of(context).pop();
          completer.complete("set_remark");
        },
      ));
//      actions.add(ActionSheetAction(
//        child: Text('把他推荐给朋友'),
//        onPressed: () {
//          Navigator.of(context).pop();
//          completer.complete("recommend_friend");
//        },
//      ));
    }

    actions.add(ActionSheetAction(
      child: Text(widget.data.isBlack ? '移除黑名单' : '加入黑名单'),
      onPressed: () {
        Navigator.of(context).pop();
        completer.complete("set_black");
      },
    ));

    if (widget.data.isFriend) {
      actions.add(ActionSheetAction(
        child: Text('删除', style: TextStyle(color: Colors.red)),
        onPressed: () {
          Navigator.of(context).pop();
          completer.complete("delete_friend");
        },
      ));
    }

    ActionSheet.show(
      context,
      actions: actions,
      cancelButton: ActionSheetAction(
        child: Text('取消'),
        onPressed: () {
          Navigator.of(context).pop();
          completer.complete("cancel");
        },
      ),
    );

    var str = await completer.future;
    if (str == "cancel") return;

    if ("set_group_remark" == str) {
      Future.microtask(() async {
        var rst = await Routers.navigateTo(
            context,
            Routers.groupMemberSetNickname +
                "?nickname=${Uri.encodeComponent(widget.data.nickname)}");

        if (rst is! String || rst.isEmpty) return;
        if (rst == widget.data.nickname) return;

        var rsp = await toSetGroupNickname(
            nickname: rst,
            groupId: widget.data.groupId,
            friendId: widget.data.friendId);
        if (!rsp.success) return Toast.showToast(context, message: rsp.message);
        var glp = GroupListProvider.of(context, listen: false);
        var group = glp.map[widget.data.groupId];
        var member =
            group.members.firstWhere((d) => d.friendId == widget.data.friendId);
        widget.data.nickname = rst;
        member.nickname = rst;
        group.serialize(forceUpdate: true);
        if (mounted) setState(() {});
      });
      return;
    }

    if ("set_remark" == str) {
      Routers.navigateTo(
          context,
          Routers.contactSetRemark +
              "?friendId=${widget.data.friendId}&remark=${Uri.encodeFull(widget.data.name)}");
      return;
    }

    // 黑名单
    if ("set_black" == str) {
      var isBlack = !widget.data.isBlack;
      var rsp = await toSetBlack(
          friendId: widget.data.friendId, black: isBlack ? 0 : 1);
      if (!rsp.success) return Toast.showToast(context, message: rsp.message);
      widget.data.isBlack = isBlack;
      var clpm = ContactListProvider.of(context, listen: false).map;
      if (widget.data.relation == _ContactRelation.friend ||
          clpm.containsKey(widget.data.friendId)) {
        var contact = clpm[widget.data.friendId];
        contact.black = widget.data.black;
        contact.serialize();
        return;
      }

      /// 其他情况有bug,更新不了，这次版本，需求有点急
      /// 待重新规划数据
      return;
    }

    if ("delete_friend" == str) {
      if (!await confirm(context,
          title: "确定删除？", content: "删除联系人\"${widget.data.name}\"")) return;

      var rsp = await toDeleteFriend(friendId: widget.data.friendId);
      if (!rsp.success) return Toast.showToast(context, message: rsp.message);
      await ChatListProvider.of(context, listen: false)
          .delete(widget.data.friendId, real: true);
      await ContactListProvider.of(context, listen: false)
          .delete(ProfileProvider().profileId, widget.data.friendId);
      Navigator.pop(context);
      return;
    }

    Toast.showToast(context, message: "正在开发($str)");
  }
}

class _LineButton extends StatelessWidget {
  final GestureTapCallback onTap;
  final String title;
  final String icon;
  final top;
  final bottom;
  final Color color;

  const _LineButton(
      {Key key,
      this.onTap,
      this.title,
      this.icon,
      this.top = false,
      this.bottom = true,
      this.color})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    var border = Border(
        top: top == true
            ? BorderSide(color: Style.pBackgroundColor, width: ew(20))
            : BorderSide.none,
        bottom: bottom == true
            ? BorderSide(color: Style.pDividerColor, width: ew(1))
            : BorderSide.none);
    return Container(
      decoration: BoxDecoration(border: border),
      child: ListTile(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            icon != null
                ? SvgPicture.asset(icon,
                    width: ew(52),
                    height: ew(52),
                    color: color ?? Style.bTextColor)
                : null,
            SizedBox(width: ew(10)),
            Text(
              title,
              textAlign: TextAlign.center,
              style:
                  TextStyle(color: color ?? Style.bTextColor, fontSize: sp(32)),
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}

/// 联系人关系类型
enum _ContactRelation { stranger, friend, groupMember, applyFriend, unknown }

/// 联系人数据
class _ContactData {
  final Map<String, dynamic> json;
  _ContactData(this.json) : assert(json != null);

  get relation => json["_relation"] as _ContactRelation;

  get isFriend => json["_isFriend"] == true;

  get name => json["_name"] as String ?? "";

  get groupId => json['groupId'] as String;

  get friendId => json['friendId'] as String;

  get avatar => json["avatar"] as String ?? "";

  get nickname => json["nickname"] as String ?? "";
  set nickname(String nickname) {
    json['nickname'] = nickname;
  }

  get mobile => json["mobile"] as String ?? "";
  get black => json["black"] as int ?? 3;

  set isBlack(bool isBlack) {
//    0 互相拉黑  1:被拉黑  2：拉黑好友   3：关系正常
    var isBlack2 = this.black == 0 || this.black == 1;
    if (isBlack) {
      json['black'] = isBlack2 ? 0 : 2;
      return;
    }
    json['black'] = isBlack2 ? 1 : 3;
  }

  /// 是否在黑名单
  get isBlack => black == 0 || black == 2;
  get sourceType => (groupId != null && groupId.isNotEmpty) ? 1 : 0;
}
