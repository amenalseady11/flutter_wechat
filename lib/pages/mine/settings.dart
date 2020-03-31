import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_wechat/providers/profile/profile.dart';
import 'package:flutter_wechat/routers/routers.dart';
import 'package:flutter_wechat/util/adapter/adapter.dart';
import 'package:flutter_wechat/util/dialog/dialog.dart';
import 'package:flutter_wechat/util/style/style.dart';
import 'package:flutter_wechat/widgets/action_sheet/action_sheet.dart';

class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
          preferredSize: Size.fromHeight(ew(80)),
          child: AppBar(
              elevation: 0,
              titleSpacing: -ew(20),
              title: Text("设置",
                  style: TextStyle(fontSize: sp(36), color: Style.tTextColor)),
              centerTitle: false,
              backgroundColor: Style.pBackgroundColor)),
      body: Column(
        children: <Widget>[
          Container(height: ew(20), color: Style.pBackgroundColor),
          ListTile(
            title: Text("隐私设置",
                style: TextStyle(fontSize: sp(32), color: Style.tTextColor)),
            onTap: () => Routers.navigateTo(context, Routers.privacySettings),
          ),
          Container(height: ew(20), color: Style.pBackgroundColor),
          ListTile(
            title: Text("关于",
                style: TextStyle(fontSize: sp(32), color: Style.tTextColor)),
            trailing: Image.asset(
                "assets/images/icons/tableview_arrow_8x13.png",
                width: ew(16),
                height: ew(26)),
            onTap: () => Routers.navigateTo(context, Routers.about),
          ),
          Divider(height: ew(1), color: Style.pDividerColor),
          ListTile(
            title: Text("诊断",
                style: TextStyle(fontSize: sp(32), color: Style.tTextColor)),
            trailing: Text("163ms"),
//            onTap: () => Routers.navigateTo(context, Routers.networkDiagnosis),
          ),
          Container(height: ew(20), color: Style.pBackgroundColor),
          ListTile(
            title: Text("退出",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: sp(32), color: Style.tTextColor)),
            onTap: () => _showLogoutAsMenu(context),
          ),
          Expanded(child: Container(color: Style.pDividerColor)),
        ],
      ),
    );
  }

  _showLogoutAsMenu(BuildContext context) async {
    Completer<String> completer = new Completer();

    List<Widget> actions = [];
    actions.add(ActionSheetAction(
      child: Text('退出登录',
          style: TextStyle(fontSize: sp(32), color: Style.tTextColor)),
      onPressed: () {
        Navigator.of(context).pop();
        completer.complete("logout");
      },
    ));

    actions.add(ActionSheetAction(
      child: Text('关闭应用',
          style: TextStyle(fontSize: sp(32), color: Style.tTextColor)),
      onPressed: () {
        Navigator.of(context).pop();
        completer.complete("close");
      },
    ));

    ActionSheet.show(
      context,
      actions: actions,
      cancelButton: ActionSheetAction(
        child: Text('取消'),
        onPressed: () {
          Navigator.of(context).pop();
          completer.complete("cancel");
        },
      ),
    );

    var rst = await completer.future;
    if ('cancel' == rst) return;

    if ("logout" == rst) {
      if (!await confirm(context, content: "退出后不会删除任何历史数据，下次登录依然可以使用本账号。"))
        return;
      ProfileProvider.of(context, listen: false).logout(context);
      Routers.navigateTo(context, Routers.login, clearStack: true);
      return;
    }

    if ("close" == rst) {
      print("rst:$rst");
      await SystemChannels.platform.invokeMethod('SystemNavigator.pop');
      try {
        exit(0);
      } catch (e) {}
      return;
    }
  }
}
