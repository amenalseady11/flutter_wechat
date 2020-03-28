import 'package:common_utils/common_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_wechat/global/global.dart';
import 'package:flutter_wechat/providers/sqflite/sqflite.dart';

enum ChatMessageStatusEnum {
  unKnow,
  complete,
  sending,
  sendError,
  loading,
  loadError
}

List<ChatMessageStatusEnum> chatMessageStatusEnums = [
  ChatMessageStatusEnum.unKnow,
  ChatMessageStatusEnum.complete,
  ChatMessageStatusEnum.sending,
  ChatMessageStatusEnum.sendError,
  ChatMessageStatusEnum.loading,
  ChatMessageStatusEnum.loadError
];

class ChatMessageStates {
  static const int voiceUnRead = 0;
  static const int voiceAlreadyRead = 1;
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
  int state = 0;
  int offset = 0;

  /// 附加字段，保留字段1
  String extra1;

  /// 附加字段，保留字段2
  String extra2;

  /// 附加字段，保留字段3
  String extra3;

  /// 附加字段，保留字段4
  String extra4;

  ChatMessageStatusEnum status = ChatMessageStatusEnum.unKnow;

  dynamic _bodyData;

  ChatMessageProvider({
    this.serializeId,
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
    this.status = ChatMessageStatusEnum.unKnow,
    this.state = 0,
    this.extra1,
    this.extra2,
    this.extra3,
    this.extra4,
  });

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
      status: chatMessageStatusEnums[json['status'] as int ?? 0],
      state: json['state'] as int ?? 0,
      extra1: json['extra1'],
      extra2: json['extra2'],
      extra3: json['extra3'],
      extra4: json['extra4'],
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
      "status": status?.index ?? 0,
      "state": state ?? 0,
      "extra1": extra1,
      "extra2": extra2,
      "extra3": extra3,
      "extra4": extra4,
    };
  }

  Future<bool> serialize({bool forceUpdate = false}) async {
    try {
      var database = await SqfliteProvider().connect();

      if (this.serializeId == null || this.serializeId.isNaN) {
        this.serializeId = null;

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
  /// Add friends
  static const String addFriends = "add-friends/json";

  /// 心跳
  static const String heartbeat = "heartbeat/time-stamp";
}
