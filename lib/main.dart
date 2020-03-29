import 'dart:io';

import 'package:common_utils/common_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_wechat/providers/chat/chat_list.dart';
import 'package:flutter_wechat/providers/contact/contact_list.dart';
import 'package:flutter_wechat/providers/group/group_list.dart';
import 'package:flutter_wechat/providers/home/home.dart';
import 'package:flutter_wechat/providers/profile/profile.dart';
import 'package:flutter_wechat/providers/sqflite/sqflite.dart';
import 'package:flutter_wechat/routers/routers.dart';
import 'package:flutter_wechat/util/dio/dio.dart';
import 'package:flutter_wechat/util/shared/shared.dart';
import 'package:flutter_wechat/util/style/style.dart';
import 'package:package_info/package_info.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'generated/i18n.dart';
import 'global/global.dart';

var isUpgrade = false;

main() async {
  /// 确保初始化
  WidgetsFlutterBinding.ensureInitialized();

  LogUtil.init(isDebug: global.isDebug);

  global.pkg = await PackageInfo.fromPlatform();

  await SqfliteProvider().connect();

  setDioConfiguration(baseUrl: global.apiBaseUrl);

  shared.sharedPreferences = await SharedPreferences.getInstance();
  ProfileProvider().deserialize();

  LogUtil.v("token: ${global.profile.authToken}", tag: "### main ###");

  String version = global.pkg.version;
  String buildNumber = global.pkg.buildNumber;

  // 拼接app version
  final String appVersion = version + '+' + buildNumber;

  // 获取缓存的版本号
  final String cacheVersion = shared.getStr(SharedKey.appVersion);

  isUpgrade = appVersion == cacheVersion;
  if (isUpgrade) await shared.setStr(SharedKey.appVersion, appVersion);

  // 注册路由
  Routers.configureRoutes(isUpgrade: isUpgrade);

  // Android状态栏透明
  if (Platform.isAndroid) {
    SystemUiOverlayStyle systemUiOverlayStyle =
        SystemUiOverlayStyle(statusBarColor: Colors.transparent);
    SystemChrome.setSystemUIOverlayStyle(systemUiOverlayStyle);
  }

  // 启动应用
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: ProfileProvider()),
        ChangeNotifierProvider.value(value: HomeProvider()),
        ChangeNotifierProvider.value(value: SqfliteProvider()),
        ChangeNotifierProvider.value(value: ContactListProvider()),
        ChangeNotifierProvider.value(value: GroupListProvider()),
        ChangeNotifierProvider.value(value: ChatListProvider()),
      ],
      child: MaterialApp(
        title: 'Flutter Wechat App',
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          S.delegate,
          RefreshLocalizations.delegate
        ],
        supportedLocales: S.delegate.supportedLocales,
        locale: Locale('zh'),
        theme: ThemeData(
            primaryColor: Color(0xFFEDEDED),
            buttonTheme: ButtonThemeData(minWidth: 44.0),
            iconTheme: IconThemeData(size: 17, color: Style.pTextColor),
            appBarTheme: AppBarTheme(
                elevation: 0.0,
                iconTheme: IconThemeData(size: 17, color: Style.pTextColor),
                textTheme: TextTheme(
                    title: TextStyle(fontSize: 17, color: Style.pTextColor))),
            scaffoldBackgroundColor: Color.fromRGBO(255, 255, 255, 1),
            hintColor: Colors.grey.withOpacity(0.3),
            splashColor: Colors.transparent,
            canvasColor: Colors.transparent),
        onGenerateRoute: Routers.generator,
        initialRoute: Routers.root,
      ),
    );
  }
}

class LocalRefreshLocalizations extends RefreshLocalizations {
  LocalRefreshLocalizations(Locale locale) : super(locale);
  RefreshString get currentLocalization {
    return values["zh"];
  }

  static const RefreshLocalizationsDelegate delegate =
      RefreshLocalizationsDelegate();

  static RefreshLocalizations of(BuildContext context) {
    return Localizations.of(context, RefreshLocalizations);
  }
}
