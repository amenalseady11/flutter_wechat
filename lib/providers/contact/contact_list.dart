import 'dart:core';

import 'package:common_utils/common_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_wechat/apis/apis.dart';
import 'package:flutter_wechat/global/global.dart';
import 'package:flutter_wechat/providers/contact/contact.dart';
import 'package:flutter_wechat/providers/sqflite/sqflite.dart';
import 'package:flutter_wechat/util/toast/toast.dart';
import 'package:provider/provider.dart';
import 'package:azlistview/azlistview.dart';

class ContactListProvider extends ChangeNotifier {
  static ContactListProvider of(BuildContext context, {bool listen = true}) {
    return Provider.of<ContactListProvider>(context, listen: listen);
  }

  static ContactListProvider _contactList = ContactListProvider._();
  factory ContactListProvider() => _contactList;

  ContactListProvider._();
  List<ContactProvider> _contacts = [];

  List<ContactProvider> get contacts => _contacts;

  /// 临时好友，添加朋友时需要
  final Map<String, Map<String, dynamic>> tmpContacts = {};

  Map<String, ContactProvider> get map =>
      _contacts.fold({}, (m, d) => m..putIfAbsent(d.friendId, () => d));

  Future<bool> deserialize() async {
    var database = await SqfliteProvider().connect();
    String profileId = global.profile.profileId;
    var list = await database.query(ContactProvider.tableName,
            where: "profileId = ?",
            whereArgs: [profileId],
            orderBy: "serializeId desc") ??
        [];
    List<ContactProvider> contacts =
        list.map((json) => ContactProvider.fromJson(json)).toList();
    this._contacts
      ..clear()
      ..addAll(contacts);

    if (this._contacts.length > 0) forceUpdate();
    return true;
  }

  Future<bool> delete(String profileId, String friendId) async {
    var database = await SqfliteProvider().connect();
    var rst = await database.update(
        ContactProvider.tableName, {"status": ContactStatus.deleted},
        where: "profileId = ? and friendId = ?",
        whereArgs: [profileId, friendId]);
    LogUtil.v("伪删除联系人信息:$friendId,$rst", tag: "### ContactListProvider ###");

    ContactProvider contact = map[friendId];
    if (contact != null) {
      _contacts.remove(contact);
      notifyListeners();
    }
    return rst > 0;
  }

  addContact(ContactProvider contact) async {
    contact.profileId = global.profile.profileId;
    contacts.add(contact);
    await contact.serialize();
    return forceUpdate();
  }

  void forceUpdate() {
    SuspensionUtil.sortListBySuspensionTag(this.contacts);
    notifyListeners();
  }

  Future<bool> remoteUpdate(BuildContext context) async {
    var profileId = global.profile.profileId;
    if (profileId == null || profileId.isEmpty) {
      LogUtil.v("远程获取联系人请登录", tag: "### ContactListProvider ###");
      return false;
    }
    var rsp = await toGetFriends();
    if (!rsp.success) {
      Toast.showToast(context, message: rsp.message);
      return false;
    }
    var list = (rsp.body as Iterable) ?? [];

    // 添加/更新/删除
    var counts = [0, 0, 0];

    var friendIds = [];

    var map = this.map;

    for (var json in list) {
      var contact = ContactProvider.fromJson({})
        ..profileId = profileId
        ..friendId = json["FriendID"] ?? ""
        ..mobile = json["MobileNumber"] ?? ""
        ..nickname = json["NickName"] ?? ""
        ..avatar = json["Avatar"] ?? ""
        ..remark = json["Remark"] ?? ""
        ..initials = json["Initial"] ?? "#"
        ..black = json["IsBlack"] ?? ContactBlackStatus.normal
        ..status = ContactStatus.normal;

      friendIds.add("'${contact.friendId}'");

      if (!map.containsKey(contact.friendId)) {
        _contacts.add(contact);
        if (!await contact.serialize()) continue;
        counts[0] = counts[0] + 1;
        map.putIfAbsent(contact.friendId, () => contact);
        continue;
      }

      var old = map[contact.friendId];
      if (old.equal(contact)) continue;

      old.updateJson(contact.toJson());
      if (!await old.serialize(forceUpdate: true)) continue;
      counts[1] = counts[1] + 1;
    }

    var database = await SqfliteProvider().connect();
    var where = "profileId = '$profileId' and status = ${ContactStatus.normal}";
    if (friendIds.isNotEmpty)
      where += " and friendId not in (${friendIds.join(",")})";
    counts[2] = await database.update(
        ContactProvider.tableName, {"status": ContactStatus.notFriend},
        where: where);

    LogUtil.v("联系人远程同步:插入${counts[0]}条；更新${counts[1]}条；伪删除${counts[2]}条。",
        tag: "### ContactListProvider ###");

    notifyListeners();

    return true;
  }

  void clear() {
    this.contacts.clear();
    this.map.clear();
    this.tmpContacts.clear();
    notifyListeners();
  }
}
