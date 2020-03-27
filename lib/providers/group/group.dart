import 'dart:convert';

import 'package:common_utils/common_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_wechat/providers/group/group_member.dart';
import 'package:flutter_wechat/providers/sqflite/sqflite.dart';

class GroupProvider extends ChangeNotifier {
  static const String tableName = "t_group";
  String profileId;
  int serializeId;
  String groupId;
  String name;
  String announcement;
  String createId;
  int status;
  DateTime instTime;

  GroupProvider(
      {this.serializeId,
      this.profileId,
      this.groupId,
      this.name,
      this.announcement,
      this.createId,
      this.status,
      this.instTime,
      this.members = const []});

  List<GroupMemberProvider> members = [];

  get avatars => members.map((d) => d.avatar).toList();

  Map<String, dynamic> toJson() {
    return {
      "serializeId": serializeId,
      "profileId": profileId,
      "groupId": groupId,
      "name": name,
      "announcement": announcement,
      "createId": createId,
      "status": status,
//      "instTime": this.instTime?.millisecondsSinceEpoch,
      "members": json.encode(members.map((d) => d.toJson()).toList())
    };
  }

  static GroupProvider fromJson(Map<String, dynamic> json) {
    return GroupProvider(
        serializeId: json["serializeId"] as int,
        profileId: json["profileId"] as String,
        groupId: json["groupId"] as String,
        name: json["name"] as String,
        announcement: json["announcement"] as String,
        createId: json["createId"] as String,
        status: json["status"] as int,
//        instTime: json['instTime'] == null
//            ? DateTime.now()
//            : DateTime.fromMillisecondsSinceEpoch(json['instTime']),
        members: (jsonDecode(json["members"]) as Iterable ?? [])
            .map((json) => GroupMemberProvider.fromJson(json))
            .toList());
  }

  Future<bool> serialize() async {
    try {
      var database = await SqfliteProvider().connect();

      if (this.serializeId == null || this.serializeId.isNaN) {
        this.serializeId = null;

        var rst = this.serializeId =
            await database.insert(GroupProvider.tableName, this.toJson());
        LogUtil.v("插入群组信息信息:$groupId,$rst");
        return rst > 0;
      }

      var rst = await database.update(GroupProvider.tableName, this.toJson(),
          where: "serializeId = ?", whereArgs: [this.serializeId]);
      LogUtil.v("更新群组信息:$groupId,$rst");
      return rst > 0;
    } catch (e) {
      LogUtil.e(e, tag: "群组序列化:$groupId");
      return false;
    }
  }

  equal(GroupProvider group) {
    group.serializeId = this.serializeId;
    group.profileId = this.profileId;
    var rst = jsonEncode(this.toJson()) == jsonEncode(group.toJson());
    return rst;
  }
}
