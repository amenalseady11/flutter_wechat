import 'package:flutter/material.dart';
import 'package:flutter_wechat/global/global.dart';

class GroupMemberRoles {
  static const int member = 0;
  static const int master = 1;
  static const int admin = 2;
}

class GroupMemberProvider extends ChangeNotifier {
  String groupId;
  String friendId;
  String mobile;
  String nickname;
  String remark;
  String avatar;

  /// [GroupMemberRoles]
  int role;

  ///  1：正常  0：全体禁言
  int forbidden;
  DateTime instTime;
  DateTime updtTime;

  GroupMemberProvider({
    this.groupId,
    this.friendId,
    this.mobile,
    this.nickname,
    this.remark,
    this.avatar,
    this.role = -1,
    this.forbidden = 0,
    this.instTime,
    this.updtTime,
  });

  get name {
    if (remark != null && remark.isNotEmpty) return remark;
    if (nickname != null && nickname.isNotEmpty) return nickname;
    return mobile ?? "";
  }

  get roleSort {
    if (isMaster) return 2;
    if (isAdmin) return 1;
    return 0;
  }

  get isAdmin => isMaster || role == GroupMemberRoles.admin;

  get isMaster => role == GroupMemberRoles.master;

  get isSelf => friendId == global.profile.friendId;

  static GroupMemberProvider fromJson(Map<String, dynamic> json) {
    return GroupMemberProvider(
        groupId: json["groupId"] as String,
        friendId: json["friendId"] as String,
        mobile: json["mobile"] as String,
        nickname: json["nickname"] as String,
        remark: json["remark"] as String,
        avatar: json["avatar"] as String,
        role: json["role"] as int,
        forbidden: json["forbidden"] as int,
        instTime: json['instTime'] == null
            ? DateTime.now()
            : DateTime.fromMillisecondsSinceEpoch(json['instTime']),
        updtTime: json['updtTime'] == null
            ? DateTime.now()
            : DateTime.fromMillisecondsSinceEpoch(json['updtTime']));
  }

  Map<String, dynamic> toJson() {
    return {
      "groupId": groupId,
      "friendId": friendId,
      "mobile": mobile,
      "nickname": nickname,
      "remark": remark,
      "avatar": avatar,
      "role": role,
      "forbidden": forbidden,
      "instTime": this.instTime?.millisecondsSinceEpoch,
      "updtTime": this.updtTime?.millisecondsSinceEpoch,
    };
  }
}
