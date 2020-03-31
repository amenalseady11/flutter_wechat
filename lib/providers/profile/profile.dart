import 'package:flutter/material.dart';
import 'package:flutter_wechat/providers/chat/chat_list.dart';
import 'package:flutter_wechat/providers/contact/contact_list.dart';
import 'package:flutter_wechat/providers/group/group_list.dart';
import 'package:flutter_wechat/util/shared/shared.dart';
import 'package:provider/provider.dart';

class ProfileProvider extends ChangeNotifier {
  static ProfileProvider _profile = ProfileProvider._();

  ProfileProvider._();
  factory ProfileProvider() {
    return _profile;
  }

  static ProfileProvider of(BuildContext context, {bool listen = true}) {
    return Provider.of<ProfileProvider>(context, listen: listen);
  }

  String friendId;
  String mobile;
  String nickname;
  String avatar;
  String authToken;

  /// qrCode 二维码盐
  int _salt = 0;
  get salt {
    if (_salt == null || _salt < 0) return 0;
    return _salt > 20 ? 20 : _salt;
  }

  set salt(int salt) {
    if (salt == null || salt < 0) this._salt = 0;
    this._salt = salt > 20 ? 20 : salt;
  }

  /// 私聊总话题偏移量
  int offset;

  get profileId => friendId;

  get isLogged => friendId != null && friendId.isNotEmpty;

  get name {
    if (nickname != null && nickname.isNotEmpty) return nickname;
    return mobile ?? "";
  }

  /// 更新
  update({
    String authToken,
    String friendId,
    String mobile,
    String nickname,
    String avatar,
    int offset,
    bool forceUpdate = false,
    bool enableNull = false,
  }) {
    if (enableNull || authToken != null) this.authToken = authToken;
    if (enableNull || friendId != null) this.friendId = friendId;
    if (enableNull || mobile != null) this.mobile = mobile;
    if (enableNull || nickname != null) this.nickname = nickname;
    if (enableNull || avatar != null) this.avatar = avatar;
    if (enableNull || offset != null) this.offset = offset;

    if (forceUpdate || nickname != null || avatar != null) {
      notifyListeners();
    }

    return this;
  }

  updateJson(
    Map<String, dynamic> json, {
    bool forceUpdate = false,
    bool enableNull = false,
  }) {
    if (json == null) return this;
    return this
      ..update(
        authToken: json['authToken'] as String,
        friendId: json["friendId"] as String,
        mobile: json["mobile"] as String,
        nickname: json["nickname"] as String,
        avatar: json["avatar"] as String,
        offset: json["offset"] as int,
        enableNull: enableNull,
        forceUpdate: forceUpdate,
      );
  }

  login({Map<String, dynamic> json}) {
    if (json != null && json.isNotEmpty) {
      updateJson(json, enableNull: true, forceUpdate: true);
    } else {
      notifyListeners();
    }
    return serialize();
  }

  toJson() {
    return {
      "authToken": authToken,
      "friendId": friendId,
      "mobile": mobile,
      "nickname": nickname,
      "avatar": avatar,
      "offset": offset,
    };
  }

  logout(BuildContext context) {
    var rst = this
      ..updateJson({}, enableNull: true, forceUpdate: true).serialize();
    ChatListProvider.of(context, listen: false).clear();
    GroupListProvider.of(context, listen: false).clear();
    ContactListProvider.of(context, listen: false).clear();
    notifyListeners();
    return rst;
  }

  serialize({bool forceUpdate: false}) async {
    bool b = await shared.setJson(SharedKey.profile, this.toJson());
    if (forceUpdate) notifyListeners();
    return b;
  }

  ProfileProvider deserialize() {
    var json = shared.getJson(SharedKey.profile);
    return this..updateJson(json);
  }
}
