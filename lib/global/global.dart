import 'package:flutter/foundation.dart';
import 'package:flutter_wechat/providers/profile/profile.dart';
import 'package:package_info/package_info.dart';
import 'package:uuid/uuid.dart';

var _uuid = Uuid();

class _Global {
  String apiBaseUrl = "http://148.70.231.222:7654";
  String uploadBaseUrl = "http://148.70.231.222:6543";

  ProfileProvider get profile => ProfileProvider();

  PackageInfo pkg;

  get isRelease => kReleaseMode;

  get isDebug => !isRelease;

  get isProduction => isRelease;

  get isDevelopment => isDebug;

  /// 区分android,ios包时候，下划线问题，ios要转成大写
  get pkgName {
    return pkg.packageName.replaceAll("_", "").toLowerCase();
  }

  isPkgSchemes(String url) {
    if (url == null) return false;
    var schemes = "imchat://${this.pkgName}?type=";
    return url.startsWith(schemes);
  }

  get uuid => _uuid.v1().replaceAll("-", "");
}

final global = _Global();
