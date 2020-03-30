import 'dart:convert';

import 'package:common_utils/common_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_wechat/global/global.dart';
import 'package:flutter_wechat/providers/group/group_list.dart';
import 'package:flutter_wechat/providers/group/group_member.dart';
import 'package:flutter_wechat/providers/sqflite/sqflite.dart';
import 'package:flutter_wechat/apis/apis.dart';
import 'package:flutter_wechat/util/toast/toast.dart';

class GroupForbiddenStatus {
  /// 0：全体禁言
  static const int forbidden = 0;

  /// 1：正常
  static const int normal = 1;
}

class GroupStatus {
  /// 0：已加入群
  static const int joined = 0;

  /// 1: 已退出群
  static const int exited = 1;

  /// 2: 已解散
  static const int dismiss = 2;
}

class GroupProvider extends ChangeNotifier {
  static const String tableName = "t_group";
  String profileId;
  int serializeId;
  String groupId;
  String _name;
  String announcement;
  String createId;

  ///  1：正常  0：全体禁言
  ///  [GroupForbiddenStatus]
  int forbidden;

  /// [GroupStatus]
  int status;
  DateTime instTime;
  DateTime updtTime;
  set name(String name) {
    _name = name;
  }

  get name {
    if (_name == null || _name.isEmpty) return "群聊";
    return _name;
  }

  GroupMemberProvider get self =>
      members.firstWhere((d) => d.friendId == global.profile.friendId,
          orElse: () => GroupMemberProvider());

  bool _fetching = false;
  bool get fetching => _fetching;

  GroupProvider(
      {this.serializeId,
      this.profileId,
      this.groupId,
      String name,
      this.announcement,
      this.createId,
      this.forbidden,
      this.status,
      this.instTime,
      this.updtTime,
      this.members = const []})
      : _name = name;

  List<GroupMemberProvider> members = [];

  get avatars => members.map((d) => d.avatar).toList();

  bool get isAdmin => isMaster;
  bool get isMaster => global.profile.profileId == createId;

  Map<String, dynamic> toJson() {
    return {
      "serializeId": serializeId,
      "profileId": profileId,
      "groupId": groupId,
      "name": name,
      "announcement": announcement,
      "createId": createId,
      "forbidden": forbidden ?? GroupForbiddenStatus.normal,
      "status": status ?? GroupStatus.joined,
      "instTime": this.instTime?.millisecondsSinceEpoch,
      "updtTime": this.updtTime?.millisecondsSinceEpoch,
      "members": json.encode(members.map((d) => d.toJson()).toList())
    };
  }

  static GroupProvider fromJson(Map<String, dynamic> json) {
    return GroupProvider(
        serializeId: json["serializeId"] as int,
        profileId: json["profileId"] as String ?? "",
        groupId: json["groupId"] as String ?? "",
        name: json["name"] as String ?? "",
        announcement: json["announcement"] as String ?? "",
        createId: json["createId"] as String ?? "",
        forbidden: json["forbidden"] as int ?? GroupForbiddenStatus.normal,
        status: json["status"] as int ?? GroupStatus.joined,
        instTime: json['instTime'] == null
            ? DateTime.now()
            : DateTime.fromMillisecondsSinceEpoch(json['instTime']),
        updtTime: json['updtTime'] == null
            ? DateTime.now()
            : DateTime.fromMillisecondsSinceEpoch(json['updtTime']),
        members: (jsonDecode(json["members"]) as Iterable ?? [])
            .map((json) => GroupMemberProvider.fromJson(json))
            .toList());
  }

  Future<bool> serialize({bool forceUpdate = false}) async {
    try {
      var database = await SqfliteProvider().connect();

      if (profileId == null) profileId = global.profile.profileId;
      if (announcement == null) announcement = "";
      if (createId == null) createId = global.profile.profileId;

      if (this.serializeId == null || this.serializeId.isNaN) {
        this.serializeId = null;

        var rst = this.serializeId =
            await database.insert(GroupProvider.tableName, this.toJson());
        LogUtil.v("插入群组信息信息:$groupId,$rst", tag: "### GroupProvider ###");
        return rst > 0;
      }

      var rst = await database.update(GroupProvider.tableName, this.toJson(),
          where: "serializeId = ?", whereArgs: [this.serializeId]);
      LogUtil.v("更新群组信息:$groupId,共$rst条", tag: "### GroupProvider ###");
      return rst > 0;
    } catch (e) {
      LogUtil.v("群组序列化异常:$groupId", tag: "### GroupProvider ###");
      LogUtil.e(e, tag: "### GroupProvider ###");
      print(new Exception());
      return false;
    } finally {
      if (forceUpdate) notifyListeners();
    }
  }

  equal(GroupProvider group) {
    group.serializeId = this.serializeId;
    group.profileId = this.profileId;
    var rst = jsonEncode(this.toJson()) == jsonEncode(group.toJson());
    return rst;
  }

  remoteUpdate(BuildContext context) async {
    if (this._fetching) return;
    if (this.status == GroupStatus.dismiss) return this;
    this._fetching = true;
    var rsp = await toGetGroup(groupId: groupId);
    this._fetching = false;
    if (!rsp.success) {
      if (rsp.message == "record not found") {
        if (this.status != GroupStatus.dismiss) {
          this.status = GroupStatus.dismiss;
          this.serialize(forceUpdate: true);
        }
      } else {
        if (context != null) Toast.showToast(context, message: rsp.message);
      }
      return this;
    }
    var glp = GroupListProvider();
    var group = await glp.saveGroupByMap(rsp.body, updateMembers: true);
    glp.forceUpdate();
    return group;
  }
}
