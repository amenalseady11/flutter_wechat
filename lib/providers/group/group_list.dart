import 'package:common_utils/common_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_wechat/apis/apis.dart';
import 'package:flutter_wechat/global/global.dart';
import 'package:flutter_wechat/providers/group/group.dart';
import 'package:flutter_wechat/providers/group/group_member.dart';
import 'package:flutter_wechat/providers/sqflite/sqflite.dart';
import 'package:flutter_wechat/util/toast/toast.dart';
import 'package:provider/provider.dart';

class GroupListProvider extends ChangeNotifier {
  static GroupListProvider of(BuildContext context, {bool listen = true}) {
    return Provider.of<GroupListProvider>(context, listen: listen);
  }

  static GroupListProvider _groupList = GroupListProvider._();
  factory GroupListProvider() => _groupList;
  GroupListProvider._();
  List<GroupProvider> groups = [];

  Map<String, GroupProvider> get map =>
      groups.fold({}, (m, d) => m..putIfAbsent(d.groupId, () => d));

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
      ..status = data["GroupModel"]["GroupChatStatus"] ?? 1;
    group.members = (data["GroupMemberDetail"] as Iterable ?? []).map((json) {
      var member = GroupMemberProvider()
        ..groupId = group.groupId
        ..friendId = json['GroupMemberID']
        ..remark = json['GroupMemberNickName'] ?? ""
        ..nickname = json['NickName'] ?? '"'
        ..mobile = json['MobileNumber'] ?? ""
        ..avatar = json['Avatar'] ?? ""
        ..role = json['GroupMemberRole']
        ..instTime = DateTime.tryParse(json['CreatedAt']);

      return member;
    }).toList();

    group.members.sort((prev, next) {
      return prev.friendId.compareTo(next.friendId);
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
      if (!_.equal(group)) group.serialize();
      map[group.groupId].members = group.members;
    }
    return group;
  }

  Future<GroupProvider> saveGroupByMap(Map<String, dynamic> json) {
    return saveGroup(convertGroup(json));
  }

  Future<bool> remoteUpdate(BuildContext context) async {
    var profileId = global.profile.profileId;
    if (profileId == null || profileId.isEmpty) {
      LogUtil.v("远程获取群组请登录");
      return false;
    }
    var rsp = await toGetGroups();
    if (!rsp.success) {
      Toast.showToast(context, message: rsp.message);
      return false;
    }
    List<GroupProvider> groups = [];
    var list = (rsp.body as Iterable) ?? [];
    for (var json in list) {
      var group = convertGroup({"GroupModel": json});
//      group.name += Random().nextInt(20).toString();
      await saveGroup(group, updateMembers: false);
      groups.add(group);
    }
    this.groups = groups;
    var ids = groups.map((d) => d.groupId).toList().join("','");
    var database = await SqfliteProvider().connect();
    var rst = 0;
    if (ids.isNotEmpty) {
      rst = await database.delete(GroupProvider.tableName,
          where: "profileId = ? and groupId not in ('$ids')",
          whereArgs: [profileId]);
    } else {
      rst = await database.delete(GroupProvider.tableName,
          where: "profileId = ?", whereArgs: [profileId]);
    }

    LogUtil.v("删除已退出/解散的群组: $rst条", tag: "GroupListProvider");

    notifyListeners();
    return true;
  }
}
