import 'dart:async';

import 'package:common_utils/common_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_wechat/global/global.dart';
import 'package:flutter_wechat/providers/chat_message/chat_message.dart';
import 'package:flutter_wechat/providers/contact/contact.dart';
import 'package:flutter_wechat/providers/group/group.dart';
import 'package:flutter_wechat/providers/sqflite/sqflite.dart';
import 'package:provider/provider.dart';

abstract class ChatSourceType {
  static const int contact = 0;
  static const int group = 1;
}

class ChatProvider extends ChangeNotifier {
  static ChatProvider of(BuildContext context, {bool listen = true}) {
    return Provider.of<ChatProvider>(context, listen: listen);
  }

  static const String tableName = "t_chat";
  int serializeId;

  String profileId;

  /// 关联编号，好友编号，群组编号
  String sourceId;

  /// 话题类型，0:私聊，1:群聊
  int sourceType = 0;

  /// 未读数量
  int unread = 0;

  /// true: 是否强制标记已读
  bool unreadTag = false;

  /// 是否置顶
  bool top = false;

  /// 是否显示，移除会话就不现实
  bool visible = false;

  /// 话题偏移量
  int offset = 0;

  /// 最近更新时间
  DateTime latestUpdateTime;

  /// 消息免打扰，静音
  bool mute = false;

  /// 是否激活状态
  bool activating = false;

  /// 排序
  DateTime get sortTime {
    if (this.top) return DateTime.now();
    return this.latestUpdateTime;
  }

  // ignore: close_sinks
  StreamController<ChatMessageProvider> controller =
      StreamController.broadcast();

  get isGroupChat => sourceType == 1 && group != null;
  get isContactChat => sourceType == 0 && contact != null;

  /// 私聊对应的联系人
  ContactProvider contact;

  /// 群聊群组信息
  GroupProvider group;

  /// 最近一条消息
  ChatMessageProvider latestMsg;

  /// 聊天消息
  final List<ChatMessageProvider> messages = [];

  ChatProvider({
    this.serializeId,
    this.profileId,
    @required this.sourceId,
    @required this.sourceType,
    this.unread = 0,
    this.unreadTag = false,
    this.top = false,
    this.visible = false,
    this.offset = 0,
    @required this.latestUpdateTime,
  });

  factory ChatProvider.fromJson(Map<String, dynamic> json) {
    return ChatProvider(
        serializeId: json["serializeId"] as int,
        profileId: json["profileId"] as String,
        sourceType: json["sourceType"] as int,
        sourceId: json["sourceId"] as String,
        unread: json["unread"] as int,
        unreadTag: (json["unreadTag"] as int == 1),
        top: (json["top"] as int == 1),
        visible: (json["visible"] as int == 1),
        offset: json["offset"] as int,
        latestUpdateTime: DateTime.fromMillisecondsSinceEpoch(
            json['latestUpdateTime'] as int));
  }

  Map<String, dynamic> toJson() {
    return {
      "serializeId": serializeId,
      "profileId": profileId,
      "sourceType": sourceType,
      "sourceId": sourceId,
      "unread": unread,
      "unreadTag": unreadTag ? 1 : 0,
      "top": top ? 1 : 0,
      "visible": visible ? 1 : 0,
      "offset": offset,
      "latestUpdateTime": latestUpdateTime?.millisecondsSinceEpoch
    };
  }

  Future<bool> serialize({bool forceUpdate: false}) async {
    try {
      var database = await SqfliteProvider().connect();

      if (profileId == null) profileId = global.profile.profileId;

      if (this.serializeId == null || this.serializeId.isNaN) {
        this.serializeId = null;

        var rst = this.serializeId =
            await database.insert(ChatProvider.tableName, this.toJson());
        LogUtil.v("话题信息:$sourceType/$sourceId/insert/success/$rst",
            tag: "### ChatProvider ###");
        return rst > 0;
      }

      var rst = await database.update(ChatProvider.tableName, this.toJson(),
          where: "serializeId = ?", whereArgs: [this.serializeId]);
      LogUtil.v("话题信息:$sourceType/$sourceId/update/$rst",
          tag: "### ChatProvider ###");
      return rst > 0;
    } catch (e) {
      LogUtil.v("话题信息:$sourceType/$sourceId/error",
          tag: "### ChatProvider ###");
      LogUtil.e(e, tag: "### ChatProvider ###");
      print(Error());
      return false;
    } finally {
      if (forceUpdate) notifyListeners();
    }
  }

  Future<ChatMessageProvider> addMessage(ChatMessageProvider message) async {
    await message.serialize(forceUpdate: true);
    if (message.sendTime.compareTo(latestUpdateTime) > 0) {
      this.latestMsg = message;
    }
    if (message.sendTime.compareTo(this.latestUpdateTime) > 0)
      this.latestUpdateTime = message.sendTime;
    this.visible = true;
    this.unreadTag = false;
    this.unread += 1;
    if (this.offset < message.offset) this.offset = message.offset;
    if (activating) {
      this.unread = 0;
      this.unreadTag = false;
      this.messages.add(message);
    }
    await this.serialize(forceUpdate: true);
    return message;
  }

  void forceUpdate() {
    notifyListeners();
  }
}
