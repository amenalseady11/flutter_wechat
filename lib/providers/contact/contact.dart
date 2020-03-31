import 'dart:convert';

import 'package:common_utils/common_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_wechat/providers/sqflite/sqflite.dart';
import 'package:azlistview/azlistview.dart';
import 'package:provider/provider.dart';

/// 联系人状态
abstract class ContactStatus {
  /// 正常（朋友状态）
  static const int friend = 0;

  /// 不是朋友（查询朋友数据不正常）
  static const int notFriend = 1;

  /// 已被删除
  static const int deleted = 2;
}

/// 黑名单状态
///  0 互相拉黑  1:被拉黑  2：拉黑好友   3：关系正常
abstract class ContactBlackStatus {
  ///  0 互相拉黑
  static const int eachBlack = 0;

  ///  1:被拉黑
  static const int coverBlack = 1;

  /// 2：拉黑好友
  static const int black = 2;

  /// 3：关系正常
  static const int normal = 3;

  /// 解析字符串黑名单
  /// TODO:后端接口返回不一致
  static int parse(dynamic black) {
    if (black is int) return black;
    if (black is! String) return normal;

    ///  IS_BLACK_EACH_OTHER string = "00" // 互相拉黑
    if ("00" == black) return eachBlack;

    ///  IS_BLACK_U_PULL_F string = "01"  // u 拉黑 f
    if ("01" == black) return black;

    /// IS_BLACK_F_PULL_U string = "10"  // f 拉黑 u
    if ("10" == black) return coverBlack;

    ///    IS_NOT_BLACK string = "11"  // 正常
    return normal;
  }
}

class ContactProvider extends ChangeNotifier implements ISuspensionBean {
  static ContactProvider of(BuildContext context, {bool listen = true}) {
    return Provider.of<ContactProvider>(context, listen: listen);
  }

  static const String tableName = "t_contact";
  String profileId;
  int serializeId;
  String friendId;
  String mobile;
  String nickname;
  String remark;
  String avatar;
  String initials;

  /// [ContactBlackStatus] 0 互相拉黑  1:被拉黑  2：拉黑好友   3：关系正常
  int black = ContactBlackStatus.normal;

  /// [ContactStatus]
  int status = ContactStatus.friend;

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
    int status,
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
        black: json["black"] as int ?? ContactBlackStatus.normal,
        status: json["status"] as int ?? ContactStatus.friend,
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
      "black": black ?? ContactBlackStatus.normal,
      "status": status ?? ContactStatus.friend,
    };
  }

  Future<bool> serialize({bool forceUpdate: false}) async {
    try {
      var database = await SqfliteProvider().connect();

      if (this.serializeId == null || this.serializeId.isNaN) {
        this.serializeId = null;

        var rst = this.serializeId =
            await database.insert(ContactProvider.tableName, this.toJson());
        LogUtil.v("插入联系人信息:$friendId,$rst", tag: "### ContactProvider ###");
        return rst > 0;
      }

      var rst = await database.update(ContactProvider.tableName, this.toJson(),
          where: "serializeId = ?", whereArgs: [this.serializeId]);
      LogUtil.v("更新联系人信息:$friendId,共$rst条", tag: "### ContactProvider ###");
      return rst > 0;
    } catch (e) {
      LogUtil.e("同步联系人异常:$friendId", tag: "### ContactProvider ###");
      LogUtil.e(e, tag: "### ContactProvider ###");
      return false;
    } finally {
      if (forceUpdate) notifyListeners();
    }
  }

  equal(ContactProvider contact) {
    contact.serializeId = this.serializeId;
    contact.profileId = this.profileId;
    return jsonEncode(this.toJson()) == jsonEncode(contact.toJson());
  }
}
