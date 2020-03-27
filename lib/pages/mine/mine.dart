import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_wechat/providers/profile/profile.dart';
import 'package:flutter_wechat/routers/routers.dart';
import 'package:flutter_wechat/util/adapter/adapter.dart';
import 'package:flutter_wechat/util/style/style.dart';
import 'package:flutter_wechat/widgets/avatar/avatar.dart';
import 'package:provider/provider.dart';

class MinePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: <Widget>[
          SizedBox(height: adapter.media.padding.top),
          _buildHead(context),
          Divider(height: ew(1), color: Style.pDividerColor),
          ListTile(
            title: Text("二维码名片"),
            onTap: () => Routers.navigateTo(context, Routers.qrCode),
            trailing: Image.asset(
                "assets/images/icons/tableview_arrow_8x13.png",
                width: ew(16),
                height: ew(26)),
          ),
          _buildLinks(context),
          Expanded(child: Container(color: Style.pBackgroundColor))
        ],
      ),
    );
  }

  _buildHead(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: ew(40), vertical: ew(60)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Selector<ProfileProvider, String>(
            selector: (context, profile) => profile.avatar ?? "",
            builder: (BuildContext context, String avatar, Widget child) {
              return CAvatar(
                heroTag: "avatar",
                avatar: avatar,
                size: ew(136),
                radius: ew(8),
                onTap: () => Routers.navigateTo(context, Routers.avatar),
              );
            },
          ),
          SizedBox(width: ew(30)),
          Expanded(
            child: GestureDetector(
              onTap: () => Routers.navigateTo(context, Routers.setNickname),
              child: Container(
                height: ew(136),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Selector<ProfileProvider, String>(
                          selector: (context, profile) => profile.name ?? "",
                          builder: (BuildContext context, String nickname,
                              Widget child) {
                            return Text(nickname,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: sp(38)));
                          }),
                      SizedBox(height: ew(12)),
                      Selector<ProfileProvider, String>(
                          selector: (context, profile) => profile.mobile ?? "",
                          builder: (BuildContext context, String mobile,
                              Widget child) {
                            return Text("手机号：" + mobile,
                                style: TextStyle(
                                    fontSize: sp(28), color: Style.mTextColor));
                          }),
                    ]),
              ),
            ),
          )
        ],
      ),
    );
  }

  _buildLinks(BuildContext context) {
    return Column(
      children: <Widget>[
        Container(height: ew(20), color: Style.pBackgroundColor),
        ListTile(
          title: Text("消息通知"),
          onTap: () => Routers.navigateTo(context, Routers.messageNotice),
          trailing: Image.asset("assets/images/icons/tableview_arrow_8x13.png",
              width: ew(16), height: ew(26)),
        ),
        Container(height: ew(20), color: Style.pBackgroundColor),
        ListTile(
          title: Text("账号与安全"),
          onTap: () => Routers.navigateTo(context, Routers.accountSecurity),
          trailing: Image.asset("assets/images/icons/tableview_arrow_8x13.png",
              width: ew(16), height: ew(26)),
        ),
        Divider(height: ew(1), color: Style.pDividerColor),
        ListTile(
          title: Text("设置"),
          onTap: () => Routers.navigateTo(context, Routers.settings),
          trailing: Image.asset("assets/images/icons/tableview_arrow_8x13.png",
              width: ew(16), height: ew(26)),
        ),
      ],
    );
  }
}
