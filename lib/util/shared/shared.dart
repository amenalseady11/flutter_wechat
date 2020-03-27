import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class SharedKey {
  /// 当前登录账号
  static const profile = "profile";

  /// 应用版本
  static String appVersion = "app_version";
}

class Shared {
  static final Shared _shared = Shared._();

  SharedPreferences sharedPreferences;

  Shared._();

  factory Shared() {
    return _shared;
  }

  getStr(String key) {
    return sharedPreferences.getString(key);
  }

  Map<String, dynamic> getJson(String key) {
    String rst = sharedPreferences.getString(key);
    if (rst == null || rst.isEmpty) return null;
    return jsonDecode(rst);
  }

  getList(String key) {
    String rst = sharedPreferences.getString(key);
    String json = jsonDecode(rst);
    if (json is! Iterable) return null;
    return (json as Iterable).toList() as List<Map<String, dynamic>>;
  }

  setJson(String key, json) {
    var str = jsonEncode(json);
    return sharedPreferences.setString(key, str);
  }

  setStr(String key, String str) {
    return sharedPreferences.setString(key, str);
  }
}

final shared = Shared();
