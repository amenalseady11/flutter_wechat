import 'package:common_utils/common_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_wechat/global/global.dart';
import 'package:flutter_wechat/providers/sqflite/sqflite.dart';

abstract class ChatMessageStatus {
  static const int unKnow = 0;
  static const int complete = 1;
  static const int sending = 2;
  static const int sendError = 3;
  static const int loading = 4;
  static const int loadError = 5;
  static const int withdrawing = 6;
  static const int withdraw = 7;
}

abstract class ChatMessageReadStatus {
  static const int unRead = 0;
  static const int alreadyRead = 1;
}

class ChatMessageProvider extends ChangeNotifier {
  static const String tableName = "t_chat_message";
  String profileId;
  int serializeId;
  String sourceId;
  String type;
  String body;
  String fromFriendId;
  String fromNickname;
  String fromAvatar;
  String toFriendId;
  String sendId;
  DateTime sendTime = DateTime.now();

  /// [ChatMessageStatus]
  int status = ChatMessageStatus.unKnow;

  /// [ChatMessageReadStatus]
  int readStatus = ChatMessageReadStatus.unRead;
  int offset = 0;

  dynamic _bodyData;

  ChatMessageProvider(
      {this.serializeId,
      this.profileId,
      this.sourceId,
      this.offset = -1,
      this.type,
      this.body,
      this.fromFriendId,
      this.fromNickname,
      this.fromAvatar,
      this.toFriendId,
      this.sendId,
      this.sendTime,
      this.status = ChatMessageStatus.unKnow,
      this.readStatus = ChatMessageReadStatus.unRead});

  get isPrivateMessage => toFriendId != null && toFriendId.isNotEmpty;

  get isGroupMessage => !isPrivateMessage;

  set bodyData(dynamic data) {
    _bodyData = data;
  }

  get bodyData {
    if (_bodyData == null) return body;
    return _bodyData;
  }

  get isSelf => fromFriendId == global.profile.friendId;

  get isLocalFile =>
      bodyData is String &&
      bodyData != null &&
      (bodyData.startsWith("/") || bodyData.startsWith("file://"));

  static ChatMessageProvider fromJson(Map<String, dynamic> json) {
    return ChatMessageProvider(
      serializeId: json["serializeId"] as int,
      profileId: json['profileId'],
      sourceId: json["sourceId"] as String,
      offset: json["offset"] as int,
      type: json["type"] as String,
      body: json["body"] as String,
      fromFriendId: json["fromFriendId"] as String,
      fromNickname: json["fromNickname"] as String,
      fromAvatar: json["fromAvatar"] as String,
      sendId: json["sendId"] as String,
      sendTime: DateTime.fromMillisecondsSinceEpoch(json["sendTime"] as int),
      status: json['status'] as int ?? ChatMessageStatus.unKnow,
      readStatus: json['readStatus'] as int ?? ChatMessageReadStatus.unRead,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "serializeId": serializeId,
      "profileId": profileId,
      "sourceId": sourceId,
      "offset": offset,
      "type": type,
      "body": body,
      "fromFriendId": fromFriendId,
      "fromNickname": fromNickname,
      "fromAvatar": fromAvatar,
      "toFriendId": toFriendId,
      "sendId": sendId,
      "sendTime": sendTime?.millisecondsSinceEpoch,
      "status": status ?? ChatMessageStatus.unKnow,
      "readStatus": readStatus ?? ChatMessageReadStatus.unRead
    };
  }

  Future<bool> serialize({bool forceUpdate = false}) async {
    try {
      var database = await SqfliteProvider().connect();

      if (this.serializeId == null || this.serializeId.isNaN) {
        this.serializeId = null;

        if (profileId == null) profileId = global.profile.profileId;

        if (this.offset > 0) {
          var list = await database.query(ChatMessageProvider.tableName,
              where: "profileId = ? and sourceId = ? and offset = ?",
              whereArgs: [profileId, sourceId, offset]);
          if (list != null && list.isNotEmpty)
            throw new Exception(
                "重复消息 profileId = $profileId and sourceId = $sourceId and offset = $offset");
        }

        var rst = this.serializeId =
            await database.insert(ChatMessageProvider.tableName, this.toJson());
        LogUtil.v("插入消息信息:$rst", tag: "### ChatMessageProvider ###");
        return rst > 0;
      }

      var rst = await database.update(
          ChatMessageProvider.tableName, this.toJson(),
          where: "serializeId = ?", whereArgs: [this.serializeId]);
      LogUtil.v("更新消息信息:$rst", tag: "### ChatMessageProvider ###");

      return rst > 0;
    } catch (e) {
      LogUtil.v("聊天信息异常:$sourceId,$type", tag: "### ChatMessageProvider ###");
      LogUtil.e(e);
      return false;
    } finally {
      if (forceUpdate) notifyListeners();
    }
  }
}

/// 消息类型
class MessageType {
  /// text message
  /// 文本消息，格式也是文本
  static const String text = "text/text";

  /// 语音消息，格式是base64
  /// voice message
  static const String base64Voice = "voice/base64";

  /// 图片消息，格式是base64
  /// img message
  static const String base64Img = "img/base64";

  ///语音消息，格式是一个语音下载地址
  /// voice message
  static const String urlVoice = "voice/url";

  /// 图片消息 格式是一个图片下载地址
  /// img message
  static const String urlImg = "img/url";

  /// 系统通知消息，格式为文本
  /// sys notify message
  static const String notify = "notify/text";

  /// 添加好友消息，格式为一个json
  /// Add friend
  static const String addFriend = "add-friend/json";

  /// 添加群组消息，格式为一个json
  static const String addGroup = "add-to-group/json";

  /// 踢出群组消息，格式为一个json
  static const String expelGroup = "expel-group/json";

  /// 心跳
  static const String heartbeat = "heartbeat/time-stamp";
}
