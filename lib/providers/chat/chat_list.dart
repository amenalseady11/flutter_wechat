import 'package:common_utils/common_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_wechat/apis/apis.dart';
import 'package:flutter_wechat/global/global.dart';
import 'package:flutter_wechat/providers/chat_message/chat_message.dart';
import 'package:flutter_wechat/providers/contact/contact.dart';
import 'package:flutter_wechat/providers/contact/contact_list.dart';
import 'package:flutter_wechat/providers/group/group.dart';
import 'package:flutter_wechat/providers/group/group_list.dart';
import 'package:flutter_wechat/providers/sqflite/sqflite.dart';
import 'package:flutter_wechat/socket/socket.dart';
import 'package:provider/provider.dart';

import 'chat.dart';

class ChatListProvider extends ChangeNotifier {
  static ChatListProvider of(BuildContext context, {bool listen = true}) {
    return Provider.of<ChatListProvider>(context, listen: listen);
  }

  static ChatListProvider _chatList = ChatListProvider._();
  factory ChatListProvider() => _chatList;
  ChatListProvider._();

  final List<ChatProvider> chats = [];

  Map<String, ChatProvider> get map =>
      chats.fold({}, (m, d) => m..putIfAbsent(d.sourceId, () => d));

  Future<bool> deserialize() async {
    try {
      var profileId = global.profile.profileId;
      var database = await SqfliteProvider().connect();

      var list = await database.query(ChatProvider.tableName,
              where: "profileId = ?",
              whereArgs: [profileId],
              orderBy: "serializeId desc") ??
          [];
      this.chats.clear();
      var contactMap = ContactListProvider().map;
      var groupMap = GroupListProvider().map;

      for (var json in list) {
        var chat = ChatProvider.fromJson(json);
        this.chats.add(chat);
        if (contactMap.isNotEmpty || groupMap.isNotEmpty) continue;
        if (chat.sourceType == 0) {
          chat.contact = contactMap[chat.sourceId];
        } else if (chat.sourceType == 1) {
          chat.group = groupMap[chat.sourceId];
        }
      }

      var map = this.map;

      var list1 = await database.query(ChatMessageProvider.tableName,
          groupBy: "sourceId", orderBy: "sendTime desc");

      list1.forEach((json) {
        var message = ChatMessageProvider.fromJson(json);
        var chat = map[message.sourceId];
        if (chat == null) return;
        chat.latestMsg = message;
      });

      if (this.chats.length > 0) {
        this.sort(forceUpdate: true);
      }
      return true;
    } catch (e) {
      LogUtil.e(e, tag: "话题列表反序列化异常");
      return false;
    }
  }

  Future<bool> delete(String sourceId, {bool real = false}) async {
    var profileId = global.profile.profileId;
    try {
      var database = await SqfliteProvider().connect();
      var chat = map[sourceId];
      chat.latestMsg = null;
      chat.messages.clear();

      // 删除消息
      database.delete(ChatMessageProvider.tableName,
          where: "profileId = ? and sourceId = ?",
          whereArgs: [profileId, sourceId]);

      if (!real) {
        chat.unreadTag = false;
        chat.top = false;
        var rst = chat.serialize(forceUpdate: true);
        this.sort(forceUpdate: true);
        return rst;
      }

      socket.remove(private: false, sourceId: sourceId);

      // 删除话题
      await database.delete(ChatProvider.tableName,
          where: "profileId = ? and groupId = ?",
          whereArgs: [profileId, sourceId]);

      // 删除群组
      database.delete(GroupProvider.tableName,
          where: "profileId = ? and groupId = ?",
          whereArgs: [profileId, sourceId]);

      this.sort(forceUpdate: true);

      return true;
    } catch (e) {
      LogUtil.e(e, tag: "删除话题:$sourceId");
      return false;
    }
  }

  sort({bool forceUpdate = false}) {
    chats.sort((d1, d2) {
      var rst = d2.sortTime.compareTo(d1.sortTime);
      if (rst != 0) return rst;
      return d2.serializeId.compareTo(d1.serializeId);
    });
    if (forceUpdate) notifyListeners();
  }

  addChat(ChatProvider chat,
      {bool sort = false, bool forceUpdate = false}) async {
    if (chat.serializeId == null) await chat.serialize(forceUpdate: false);
    chats.add(chat);
    if (sort) this.sort();
    notifyListeners();
  }

  void forceUpdate() {
    notifyListeners();
  }

  void clear() {
    this.chats.clear();
    this.map.clear();
    notifyListeners();
  }

  ChatProvider getChat(
      {int sourceType, String sourceId, bool created = false}) {
    var chat = this.map[sourceId];
    if (chat != null) return chat;
    if (!created) return chat;

    chat = ChatProvider(
        sourceId: sourceId,
        sourceType: sourceType,
        profileId: global.profile.profileId,
        latestUpdateTime: DateTime(2020, 2, 1));

    return chat;
  }

  Future<ChatProvider> getChatAsync({int sourceType, String sourceId}) async {
    ChatProvider chat =
        getChat(sourceType: sourceType, sourceId: sourceId, created: true);
    if (chat.serializeId != null) return chat;

    // 因为私聊是一个连接，可能出现没有本地没有联系人情况，确收到消息
    // 只有私聊才有这种情况
    if (sourceType == ChatSourceType.contact) {
      var rsp = await toGetUserBriefly(friendId: sourceId);
      if (!rsp.success) return chat;
      var contact = ContactProvider.fromJson({});
      contact.profileId = global.profile.profileId;
      contact.friendId = sourceId;
      contact.avatar = rsp.body["Avatar"] as String ?? "";
      contact.nickname = rsp.body["NickName"] as String ?? "";
      contact.mobile = rsp.body["MobileNumber"] as String ?? "";
      chat.contact = contact;
    }

    return chat;
  }
}
