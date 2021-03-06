import 'dart:math';

import 'package:common_utils/common_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_wechat/apis/apis.dart';
import 'package:flutter_wechat/global/global.dart';
import 'package:flutter_wechat/providers/chat/chat.dart';
import 'package:flutter_wechat/providers/chat/chat_list.dart';
import 'package:flutter_wechat/providers/chat_message/chat_message.dart';
import 'package:flutter_wechat/providers/contact/contact.dart';
import 'package:flutter_wechat/providers/contact/contact_list.dart';
import 'package:flutter_wechat/providers/group/group.dart';
import 'package:flutter_wechat/providers/group/group_list.dart';
import 'package:flutter_wechat/providers/sqflite/sqflite.dart';
import 'package:flutter_wechat/service/socket_service.dart';
import 'package:flutter_wechat/util/toast/toast.dart';
import 'package:provider/provider.dart';

abstract class SyncService {
  static _remoteUpdate(BuildContext context) async {
    var updates = await Future.wait([
      Provider.of<ContactListProvider>(context, listen: false)
          .remoteUpdate(context),
      Provider.of<GroupListProvider>(context, listen: false)
          .remoteUpdate(context),
    ]);
    if (updates.contains(false)) {
      Toast.showToast(context, message: "网络连接失败!");
//      _remoteUpdate(context);
    }
  }

  static clearDB() async {
    var profileId = global.profile.profileId ?? "";
    if (profileId.isEmpty) return;
    var database = await SqfliteProvider().connect();
    var where = "profileId = '$profileId'";
    await Future.wait([
      database.delete(ChatProvider.tableName, where: where),
      database.delete(ChatMessageProvider.tableName, where: where),
      database.delete(ContactProvider.tableName, where: where),
      database.delete(GroupProvider.tableName, where: where),
    ]);
  }

  static toSyncData(BuildContext context) async {
    // TODO: 开发模式调试，清空数据库
//    if (global.isDevelopment) clearDB();

    if (global.profile.avatar.isEmpty) {
      Future.microtask(() async {
        var avatar = "assets/images/avatar/${Random().nextInt(9)}.jpg";
        var byteData = await rootBundle.load(avatar);
        var file = MultipartFile.fromBytes(byteData.buffer.asInt8List(),
            filename: avatar, contentType: MediaType("image", "jpg"));
        var rsp = await toUploadFile2(file);
        if (!rsp.success) Toast.showToast(context, message: rsp.message);
        global.profile.avatar = rsp.body as String ?? "";
        toUpdateProfile(
            avatar: global.profile.avatar,
            nickname: "用户" + global.profile.mobile.substring(7));
        global.profile.serialize(forceUpdate: true);
      });
    }

    await Future.wait([
      Provider.of<GroupListProvider>(context, listen: false).deserialize(),
      Provider.of<ContactListProvider>(context, listen: false).deserialize(),
    ]);

    await Future.wait<dynamic>([
      Provider.of<ChatListProvider>(context, listen: false).deserialize(),
      _remoteUpdate(context)
    ]);

    var chatMap = Provider.of<ChatListProvider>(context, listen: false).map;
    var contacts =
        Provider.of<ContactListProvider>(context, listen: false).contacts;
    var groups = Provider.of<GroupListProvider>(context, listen: false).groups;

    for (ContactProvider contact in contacts) {
      ChatProvider chat = chatMap[contact.friendId];
      if (chat != null) {
        chat.contact = contact;
        continue;
      }
      chat = ChatProvider(
        profileId: global.profile.profileId,
        sourceType: ChatSourceType.contact,
        sourceId: contact.friendId,
        latestUpdateTime: DateTime(2020, 2, 1),
        visible: false,
      )..contact = contact;
      await chat.serialize(forceUpdate: true);
      Provider.of<ChatListProvider>(context, listen: false).chats.add(chat);
    }

    Map<String, List<GroupProvider>> groupMap = {};
    for (GroupProvider group in groups) {
      ChatProvider chat = chatMap[group.groupId];
      if (chat != null) {
        chat.group = group;
        continue;
      }
      chat = chatMap[group.groupId] = ChatProvider(
        profileId: global.profile.profileId,
        sourceType: ChatSourceType.group,
        sourceId: group.groupId,
        latestUpdateTime: group.instTime,
        visible: false,
      )..group = group;
      await chat.serialize(forceUpdate: true);
      Provider.of<ChatListProvider>(context, listen: false).chats.add(chat);

      if (!groupMap.containsKey(group.groupId))
        groupMap.putIfAbsent(group.groupId, () => []);
      groupMap[group.groupId].add(group);
    }

    var clp = Provider.of<ChatListProvider>(context, listen: false);
    LogUtil.v("话题列表：${clp.chats.length}", tag: "### HomePage ###");
    if (clp.chats.length > 0) clp.forceUpdate();

    socket.open(true, global.profile.profileId, () => global.profile.offset);

    chatMap = Provider.of<ChatListProvider>(context, listen: false).map;
    for (GroupProvider group in groups) {
      if (group.status != GroupStatus.joined) continue;
      var chat = chatMap[group.groupId];
      socket.open(false, chat.sourceId, () => chat.offset);
    }
  }
}
