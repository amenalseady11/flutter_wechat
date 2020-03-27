part of 'apis.dart';

/// 5.1 监听私有消息 (/topic/private)

/// 5.2 监听群消息 (/topic/group/$groupId)

/// 5.3 发送好友消息
Future<DioResponse> toSendPrivateMessage(
    {@required String friendId, @required String type, @required String body}) {
  return dio.put("/topic/private/$friendId",
      data: {"ContentType": type, "Body": body}).then((res) => res.data);
}

/// 5.4 发送群消息
Future<DioResponse> toSendGroupMessage(
    {@required String groupId, @required String type, @required String body}) {
  return dio.put("/topic/group/$groupId",
      data: {"ContentType": type, "Body": body}).then((res) => res.data);
}

/// 5.3.4 发送消息
Future<DioResponse> toSendMessage(
    {bool private = true,
    @required String sourceId,
    @required String type,
    @required String body}) {
  if (private)
    return toSendPrivateMessage(friendId: sourceId, type: type, body: body);
  return toSendGroupMessage(groupId: sourceId, type: type, body: body);
}

/// 5.5 获取自己在指定话题的监听位置，也就是offset
/// 根据[sourceId]获取主题的offset
/// 私聊用[friendId]
/// 群聊用[groupId]
Future<DioResponse> toGetTopicOffset({@required String sourceId}) {
  return dio.get("/topic/offset/$sourceId").then((res) => res.data);
}
