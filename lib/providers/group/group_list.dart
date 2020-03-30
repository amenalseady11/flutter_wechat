import 'package:common_utils/common_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_wechat/apis/apis.dart';
import 'package:flutter_wechat/global/global.dart';
import 'package:flutter_wechat/providers/group/group.dart';
import 'package:flutter_wechat/providers/group/group_member.dart';
import 'package:flutter_wechat/providers/sqflite/sqflite.dart';
import 'package:flutter_wechat/util/toast/toast.dart';
import 'package:provider/provider.dart';

class GroupListProvider extends ChangeNotifier {
  static GroupListProvider of(BuildContext context, {bool listen = true}) {
    if (context == null) return GroupListProvider();
    return Provider.of<GroupListProvider>(context, listen: listen);
  }

  static GroupListProvider _groupList = GroupListProvider._();
  factory GroupListProvider() => _groupList;
  GroupListProvider._();
  List<GroupProvider> groups = [];

  Map<String, GroupProvider> get map =>
      groups.fold({}, (m, d) => m..putIfAbsent(d.groupId, () => d));

  bool _loading = false;

  Future<bool> deserialize() async {
    try {
      String profileId = global.profile.profileId;
      var database = await SqfliteProvider().connect();

      var list1 = await database.query(GroupProvider.tableName,
          where: 'profileId = ?', whereArgs: [profileId]);
      groups.addAll(list1.map((json) => GroupProvider.fromJson(json)).toList());

      notifyListeners();
      return true;
    } catch (e) {
      LogUtil.e(e, tag: "群组列表反序列化失败");
      return false;
    }
  }

  void clear() {
    this.groups.clear();
    this.map.clear();
    notifyListeners();
  }

  GroupProvider convertGroup(Map<String, dynamic> data) {
    var group = GroupProvider()
      ..profileId = global.profile.profileId
      ..groupId = data["GroupModel"]["ID"]
      ..name = data["GroupModel"]["GroupName"] ?? ""
      ..announcement = data["GroupModel"]["GroupAnnouncement"] ?? ""
      ..createId =
          data["GroupModel"]["GreateUserID"] ?? global.profile.profileId
      ..instTime =
          DateTime.tryParse(data["GroupModel"]['CreatedAt']) ?? DateTime.now()
      ..updtTime =
          DateTime.tryParse(data["GroupModel"]['UpdatedAt']) ?? DateTime.now()
      ..forbidden =
          data["GroupModel"]["GroupChatStatus"] ?? GroupForbiddenStatus.normal
      ..status = GroupStatus.joined;

    if (group.name.isEmpty) group.name = "群聊";
    group.members = (data["GroupMemberDetail"] as Iterable ?? []).map((json) {
      var member = GroupMemberProvider()
        ..groupId = group.groupId
        ..friendId = json['GroupMemberID']
        ..remark = json['GroupMemberNickName'] ?? ""
        ..nickname = json['NickName'] ?? '"'
        ..mobile = json['MobileNumber'] ?? ""
        ..avatar = json['Avatar'] ?? ""
        ..role = json['GroupMemberRole']
        ..instTime = DateTime.tryParse(json['CreatedAt']) ?? DateTime.now()
        ..updtTime = DateTime.tryParse(json['UpdatedAt']) ?? DateTime.now();

      return member;
    }).toList();

    group.members.sort((prev, next) {
      return prev.instTime.compareTo(next.instTime);
    });
    return group;
  }

  Future<GroupProvider> saveGroup(GroupProvider group,
      {bool updateMembers = true}) async {
    var map = this.map;

    if (group.name.contains("(")) {
      group.name = group.name.split("(")[0];
    }
    if (!map.containsKey(group.groupId)) {
      group.profileId = global.profile.profileId;
      await group.serialize();
      groups.insert(0, group);
    } else {
      var _ = map[group.groupId];
      if (!updateMembers) group.members = _.members;
      if (!_.equal(group)) group.serialize(forceUpdate: true);
      map[group.groupId].members = group.members;
      group = map[group.groupId];
    }
    return group;
  }

  Future<GroupProvider> saveGroupByMap(Map<String, dynamic> json,
      {bool updateMembers = false}) {
    return saveGroup(convertGroup(json), updateMembers: updateMembers);
  }

  Future<bool> remoteUpdate(BuildContext context) async {
    var profileId = global.profile.profileId;
    if (profileId == null || profileId.isEmpty) {
      LogUtil.v("远程获取群组请登录", tag: "### GroupListProvider ###");
      return false;
    }
    if (_loading) return false;
    _loading = true;
    var rsp = await toGetGroups();
    _loading = false;
    if (!rsp.success) {
      Toast.showToast(context, message: rsp.message);
      return false;
    }

    var map = this.map;

    // 添加/更新/删除
    var counts = [0, 0, 0];

    var list = (rsp.body as Iterable) ?? [];
    var groupIds = [];
    for (var json in list) {
      var group = convertGroup({"GroupModel": json});
      if (group.name.contains("(")) group.name = group.name.split("(")[0];

      groupIds.add("'${group.groupId}'");

      if (!map.containsKey(group.groupId)) {
        group.profileId = global.profile.profileId;
        if (!await group.serialize()) continue;
        this.groups.insert(0, group);
        map.putIfAbsent(group.groupId, () => group);
        counts[0] = counts[0] + 1;
        continue;
      }
      GroupProvider old = map[group.groupId];
      group.members = old.members;
      if (old.equal(group)) continue;
      if (!await group.serialize(forceUpdate: true)) continue;
      var index = this.groups.indexOf(old);
      this.groups[index] = group;
      map[group.groupId] = group;
      counts[1] = counts[1] + 1;
    }

    var database = await SqfliteProvider().connect();
    var where = "profileId = '$profileId' and status = ${GroupStatus.joined}";
    if (groupIds.isNotEmpty)
      where += " and groupId not in (${groupIds.join(",")})";

    counts[2] = await database.update(
        GroupProvider.tableName, {"status": GroupStatus.exited},
        where: where);

    LogUtil.v("联系人远程同步:插入${counts[0]}条；更新${counts[1]}条；伪删除${counts[2]}条。",
        tag: "### GroupListProvider ###");

    Future.microtask(() async {
      for (var group in this.groups) {
        if (group.members.length > 0) continue;
        if (group.fetching) continue;
        group.remoteUpdate(context);
      }
    });

    notifyListeners();
    return true;
  }

  forceUpdate() {
    notifyListeners();
  }
}
