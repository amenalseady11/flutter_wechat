import 'dart:convert';

import 'package:common_utils/common_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_wechat/providers/sqflite/sqflite.dart';
import 'package:azlistview/azlistview.dart';

class ContactProvider extends ChangeNotifier implements ISuspensionBean {
  static const String tableName = "t_contact";
  String profileId;
  int serializeId;
  String friendId;
  String mobile;
  String nickname;
  String remark;
  String avatar;
  String initials;

  ///  0 互相拉黑  1:被拉黑  2：拉黑好友   3：关系正常
  int black;

  bool isShowSuspension = false;
  getSuspensionTag() => initials ?? "#";

  String get name {
    if (remark != null && remark.isNotEmpty) return remark;
    if (nickname != null && nickname.isNotEmpty) return nickname;
    if (mobile != null && mobile.isNotEmpty) return mobile;
    return "";
  }

  ContactProvider._();

  ContactProvider update({
    bool enableUpdate = true,
    bool forceUpdate = false,
    bool enableNull = true,
    int serializeId,
    String profileId,
    String friendId,
    String mobile,
    String nickname,
    String remark,
    String avatar,
    String initials,
    int black,
  }) {
    if (enableNull || serializeId != null) this.serializeId = serializeId;
    if (enableNull || profileId != null) this.profileId = profileId;
    if (enableNull || friendId != null) this.friendId = friendId;
    if (enableNull || mobile != null) this.mobile = mobile;
    if (enableNull || nickname != null) this.nickname = nickname;
    if (enableNull || remark != null) this.remark = remark;
    if (enableNull || avatar != null) this.avatar = avatar;
    this.initials = initials == null || initials.isEmpty ? "#" : initials;
    if (enableNull || black != null) this.black = black;

    if (!enableUpdate) return this;
    if (forceUpdate || remark != null || black != null) {
      notifyListeners();
    }
    return this;
  }

  ContactProvider updateJson(
    Map<String, dynamic> json, {
    bool enableUpdate = true,
    bool forceUpdate = false,
    bool enableNull = true,
  }) {
    if (json == null || json.isEmpty) return this;
    return this
      ..update(
        serializeId: json["serializeId"] as int,
        profileId: json["profileId"] as String,
        friendId: json["friendId"] as String,
        mobile: json["mobile"] as String,
        nickname: json["nickname"] as String,
        avatar: json["avatar"] as String,
        remark: json["remark"] as String,
        initials: json["initials"] as String,
        black: json["black"] as int,
        enableUpdate: enableUpdate,
        enableNull: enableNull,
        forceUpdate: forceUpdate,
      );
  }

  factory ContactProvider.fromJson(Map<String, dynamic> json) {
    return ContactProvider._()..updateJson(json, enableUpdate: false);
  }

  Map<String, dynamic> toJson() {
    return {
      "serializeId": serializeId,
      "profileId": profileId,
      "friendId": friendId,
      "mobile": mobile,
      "nickname": nickname,
      "avatar": avatar,
      "remark": remark,
      "initials": initials,
      "black": black,
    };
  }

  Future<bool> serialize() async {
    try {
      var database = await SqfliteProvider().connect();

      if (this.serializeId == null || this.serializeId.isNaN) {
        this.serializeId = null;

        var rst = this.serializeId =
            await database.insert(ContactProvider.tableName, this.toJson());
        LogUtil.v("插入联系人信息:$rst");
        return rst > 0;
      }

      var rst = await database.update(ContactProvider.tableName, this.toJson(),
          where: "serializeId = ?", whereArgs: [this.serializeId]);
      LogUtil.v("更新联系人信息:$rst");
      return rst > 0;
    } catch (e) {
      LogUtil.e(e, tag: "联系人序列化:$friendId");
      return false;
    }
  }

  equal(ContactProvider contact) {
    contact.serializeId = this.serializeId;
    contact.profileId = this.profileId;
    return jsonEncode(this.toJson()) == jsonEncode(contact.toJson());
  }
}
