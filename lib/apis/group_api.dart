part of 'apis.dart';

/// 3.1 创建群
Future<DioResponse> toAddGroup(
    {@required List<String> friendIds, String name, String announcement}) {
  return dio.post("/group", data: {
    "GroupName": name ?? "",
    "GroupAnnouncement": announcement ?? "",
    "GroupMembers": friendIds.join(",")
  }).then((res) => res.data);
}

/// 3.2 更新群公告与群名称
Future<DioResponse> toUpdateGroup(
    {@required String groupId, String name, String announcement}) {
  assert((name ?? announcement) != null);
  return dio.put("/group", data: {
    "ID": groupId,
    "GroupName": name,
    "GroupAnnouncement": announcement
  }).then((res) => res.data);
}

/// 3.3 获取群基本信息 以及成员列表
Future<DioResponse> toGetGroup({@required String groupId}) {
  return dio.get("/group/$groupId").then((res) => res.data);
}

/// 3.4 邀请新成员加入
Future<DioResponse> toInviteJoinGroup(
    {@required String groupId, @required List<String> friendIds}) {
  return dio.post("/group-member/join", data: {
    "GroupID": groupId,
    "UserID": friendIds.join(","),
  }).then((res) => res.data);
}

/// 3.5 剔除成员/
Future<DioResponse> toDeleteGroupMember(
    {@required String groupId, @required String friendId}) {
  return dio.delete("/group-member/remove", data: {
    "GroupID": groupId,
    "UserID": friendId,
  }).then((res) => res.data);
}

/// 3.6 更新禁言状态
/// [forbidden] 1：正常  0：全体禁言
Future<DioResponse> toSetGroupForbidden(
    {@required String groupId, @required int forbidden}) {
  return dio.put("/group/global/forbidden/words", data: {
    "ID": groupId,
    "GroupChatStatus": forbidden,
  }).then((res) => res.data);
}

/// 3.7 设置管理员
/// [role]
Future<DioResponse> toSetGroupMemberRole(
    {@required String groupId, @required String friendId, @required int role}) {
  return dio.put("/group-member/admin", data: {
    "GroupID": groupId,
    "GroupMemberID": friendId,
    "GroupMemberRole": role
  }).then((res) => res.data);
}

/// 3.8 设置昵称
Future<DioResponse> toSetGroupNickname(
    {@required String groupId,
    @required String friendId,
    @required String nickname}) {
  return dio.put("/group-member/nick-name", data: {
    "GroupID": groupId,
    "GroupMemberID": friendId,
    "GroupMemberNickName": nickname
  }).then((res) => res.data);
}

/// 3.9 退出群聊
Future<DioResponse> toSignOutGroup(
    {@required String groupId, @required String friendId}) {
  return dio.delete("/group-member/sign-out", data: {
    "GroupID": groupId,
    "GroupMemberID": friendId
  }).then((res) => res.data);
}

/// 3.10 根据群昵称查询成员信息

/// 3.11 群主解散群
Future<DioResponse> toDismissGroup({@required String groupId}) {
  return dio.delete("/group/$groupId").then((res) => res.data);
}

/// 3.12 群消息验证 是否可以发消息

/// 3.13 查询当前用户已经加入的群
Future<DioResponse> toGetGroups() {
  return dio.get("/group/join/items").then((res) => res.data);
}
