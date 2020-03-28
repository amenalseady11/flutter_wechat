import 'package:flutter/material.dart';
import 'package:flutter_wechat/pages/home/home.dart';
import 'package:flutter_wechat/pages/login/login.dart';
import 'package:flutter_wechat/providers/home/home.dart';
import 'package:flutter_wechat/providers/profile/profile.dart';
import 'package:flutter_wechat/util/adapter/adapter.dart';
import 'package:provider/provider.dart';

class RootPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // 适配器
    adapter.init(context);
    HomeProvider.of(context, listen: false).tab = 0;
    return Selector<ProfileProvider, bool>(
        selector: (BuildContext context, ProfileProvider profile) =>
            profile.isLogged,
        builder: (context, isLogged, child) =>
            isLogged ? HomePage() : LoginPage());
  }
}
