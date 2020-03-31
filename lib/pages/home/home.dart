import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_wechat/pages/chat/chats.dart';
import 'package:flutter_wechat/pages/contact/contacts.dart';
import 'package:flutter_wechat/pages/discover/discover.dart';
import 'package:flutter_wechat/pages/home/widgets/home_app_bar.dart';
import 'package:flutter_wechat/pages/mine/mine.dart';
import 'package:flutter_wechat/pages/mine/qr_code_scan.dart';
import 'package:flutter_wechat/providers/home/home.dart';
import 'package:flutter_wechat/routers/routers.dart';
import 'package:flutter_wechat/service/sync_service.dart';
import 'package:flutter_wechat/socket/socket.dart';
import 'package:flutter_wechat/util/adapter/adapter.dart';
import 'package:flutter_wechat/util/style/style.dart';
import 'package:flutter_wechat/widgets/menu/menu.dart';
import 'package:flutter_wechat/widgets/rotation/rotation.dart';
import 'package:provider/provider.dart';

class _HomeSubPage {
  const _HomeSubPage({
    this.title,
    this.page,
    this.icon,
    this.activeIcon,
    this.showTitle = true,
  });

  final String title;
  final String icon;
  final String activeIcon;
  final Widget page;
  final bool showTitle;
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<_HomeSubPage> _pages = [];
  List<BottomNavigationBarItem> bars = [];
  PageController _page;

  GlobalKey<MenuWidgetState> _menuKey = GlobalKey(debugLabel: 'menu_key');
  GlobalKey<MenuWidgetState> _appKey = GlobalKey(debugLabel: 'app_key');

  @override
  void initState() {
    super.initState();
    _page = PageController(
        initialPage: HomeProvider.of(context, listen: false).tab);

    _pages.addAll([
      _HomeSubPage(
          title: "会话",
          icon: ("assets/images/tabbar/icons_outlined_chats.svg"),
          activeIcon: ("assets/images/tabbar/icons_filled_chats.svg"),
          page: ChatsPage()),
      _HomeSubPage(
          title: "联系人",
          icon: ("assets/images/tabbar/icons_outlined_contacts.svg"),
          activeIcon: ("assets/images/tabbar/icons_filled_contacts.svg"),
          page: ContactsPage()),
      _HomeSubPage(
          title: "发现",
          icon: ("assets/images/tabbar/icons_outlined_discover.svg"),
          activeIcon: ("assets/images/tabbar/icons_filled_discover.svg"),
          page: DiscoverPage()),
      _HomeSubPage(
          title: "我",
          showTitle: false,
          icon: ("assets/images/tabbar/icons_outlined_me.svg"),
          activeIcon: ("assets/images/tabbar/icons_filled_me.svg"),
          page: MinePage()),
    ]);

    var w = ew(56);
    for (int i = 0; i < _pages.length; i++) {
      _HomeSubPage sub = _pages[i];
      bars.add(
        BottomNavigationBarItem(
          icon: Padding(
            padding: EdgeInsets.only(bottom: ew(4)),
            child: SvgPicture.asset(sub.icon, width: w, height: w),
          ),
          activeIcon: Padding(
            padding: EdgeInsets.only(bottom: ew(4)),
            child: SvgPicture.asset(sub.activeIcon,
                color: Style.pTintColor, width: w, height: w),
          ),
          title: Text(sub.title, style: TextStyle(fontSize: sp(24.0))),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final BottomNavigationBar bottomNavigationBar = BottomNavigationBar(
      items: bars,
      type: BottomNavigationBarType.fixed,
      currentIndex: HomeProvider.of(context, listen: false).tab,
      fixedColor: Style.pTintColor,
      unselectedItemColor: Style.pTextColor,
      onTap: (int index) {
        HomeProvider.of(context, listen: false).tab = index;
        if (mounted) setState(() {});
        _page.jumpToPage(HomeProvider.of(context, listen: false).tab);
      },
      unselectedFontSize: sp(36.0),
      selectedFontSize: sp(36.0),
      elevation: 0,
    );

    Widget body = ScrollConfiguration(
      behavior: MyBehavior(),
      child: PageView.builder(
        itemBuilder: (BuildContext context, int index) => _pages[index].page,
        controller: _page,
        itemCount: bars.length,
        physics: Platform.isAndroid
            ? ClampingScrollPhysics()
            : NeverScrollableScrollPhysics(),
        onPageChanged: (int index) {
          var tab = HomeProvider.of(context, listen: false).tab;
          if (tab == index) return;
          HomeProvider.of(context, listen: false).tab = index;
          if (mounted) setState(() {});
        },
      ),
    );

    var bottomBar = Theme(
      data: ThemeData(
        canvasColor: Colors.grey[50],
        highlightColor: Colors.transparent,
        splashColor: Colors.transparent,
      ),
      child: Container(
        decoration: BoxDecoration(
            border: Border(
                top: BorderSide(color: Style.pDividerColor, width: ew(0.4)))),
        child: bottomNavigationBar,
      ),
    );

    return FutureProvider(
      initialData: true,
      create: (context) async {
        if (socket.started) return false;
        await Future.microtask(() {});
        await SyncService.toSyncData(context);
        return false;
      },
      child: Consumer<bool>(
        child: Material(
          child: Stack(
            children: <Widget>[
              Scaffold(
                appBar: HomeAppBar(
                    key: _appKey,
                    title: _pages[HomeProvider.of(context).tab].title,
                    onPressed: () {
                      _menuKey.currentState.visible = true;
                    }),
                body: body,
                bottomNavigationBar: bottomBar,
              ),
              MenuWidget(
                  key: _menuKey,
                  menus: <MenuItem>[
                    MenuItem(
                        "add_group_chat",
                        "assets/images/contacts/icons_filled_chats.svg",
                        "发起群聊"),
                    MenuItem(
                        "add_contact",
                        "assets/images/contacts/icons_filled_add-friends.svg",
                        "添加朋友"),
                    MenuItem("qrcode_scan",
                        "assets/images/icons/icons_filled_scan.svg", "扫一扫"),
//                MenuItem("help",
//                    "assets/images/contacts/icons_filled_chats.svg", "帮助与反馈"),
                  ],
                  onTap: _onTapMenu),
            ],
          ),
        ),
        builder: (context, loading, child) {
          return AbsorbPointer(absorbing: loading, child: child);
        },
      ),
    );
  }

  void _onTapMenu(String key) async {
    if (key == null || key.isEmpty) return;
    if ("add_group_chat" == key) {
      return Routers.navigateTo(context, Routers.groupAddMember);
    }
    if ("add_contact" == key) {
      return Routers.navigateTo(context, Routers.addContact);
    }

    if ("qrcode_scan" == key) {
      if (!await QrCodeScanPage.check(context)) return;
      return Routers.navigateTo(context, Routers.qrCodeScan);
    }
  }
}

class MyBehavior extends ScrollBehavior {
  @override
  Widget buildViewportChrome(
      BuildContext context, Widget child, AxisDirection axisDirection) {
    if (Platform.isAndroid || Platform.isFuchsia) {
      return child;
    } else {
      return super.buildViewportChrome(context, child, axisDirection);
    }
  }
}
