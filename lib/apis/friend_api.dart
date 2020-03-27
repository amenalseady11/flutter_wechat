part of 'apis.dart';

/// 2.1 添加好友
Future<DioResponse> toAddFriend({
  @required String friendId,
  String reason,
  String remark,
}) {
  Map<String, dynamic> data = {"FriendID": friendId, "UtoFRemark": remark};
  return dio.post("/friend", data: data).then((res) => res.data);
}

/// 2.2 获取当前用户添加好友的请求
Future<DioResponse> toGetAddFriendApplies({int pageNo = 1, int pageSize = 20}) {
  return dio.get("/friend/add-friend-req/items").then((res) => res.data);
}

/// 2.3 更新添加好友状态（拒绝/同意）
Future<DioResponse> toApproveAddContactApply(
    {@required String applyId,
    @required String friendId,
    int state = 1,
    String remark}) {
  Map<String, dynamic> data = {
    "ID": applyId, // 当前请求数据库记录ID
    "State": state, // 1：同意 0：拒绝
    "ReqId": friendId, // 请求方用户ID
    "FtoURemark": remark ?? ""
  };
  return dio
      .put("/friend/update-friend-req", data: data)
      .then((res) => res.data);
}

/// 2.4 获取好友列表
Future<DioResponse> toGetFriends() {
  return dio.get("/friend").then((res) => res.data);
}

/// 2.5 好友黑名单设置（将好友加入or移除黑名单）
/// [friendId] 联系人编号
/// [black]  0 拉黑  1 正常
Future<DioResponse> toSetBlack(
    {@required String friendId, @required int black}) {
  return dio.put("/friend/black",
      data: {"FriendID": friendId, "IsBlack": black}).then((res) => res.data);
}

/// 2.6 根据手机号搜索好友（添加好友使用）
/// [friendId] 联系人编号
Future<DioResponse> toSearchConcat({@required String phone}) {
  return dio.get("/friend/search/$phone").then((res) => res.data);
}

/// 2.7 删除好友
/// [friendId] 联系人编号
Future<DioResponse> toDeleteFriend({@required String friendId}) {
  return dio.delete("/friend/$friendId").then((res) => res.data);
}

/// 根据[friendId]好友编号获取好友信息
Future<DioResponse> toGetUserBriefly({@required String friendId}) {
  return dio.get("/user/briefly/$friendId").then((res) => res.data);
}
