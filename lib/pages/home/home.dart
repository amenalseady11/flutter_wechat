import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_wechat/pages/chat/chats.dart';
import 'package:flutter_wechat/pages/contact/contacts.dart';
import 'package:flutter_wechat/pages/discover/discover.dart';
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

  bool _loading = true;

  _initData() async {
    if (socket.started) {
      _loading = false;
      return;
    }

    await Future.microtask(() {});
    await SyncService.toSyncData(context);

    _loading = false;
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    this._initData();
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
        page: ContactsPage(),
      ),
      _HomeSubPage(
        title: "发现",
        icon: ("assets/images/tabbar/icons_outlined_discover.svg"),
        activeIcon: ("assets/images/tabbar/icons_filled_discover.svg"),
        page: DiscoverPage(),
      ),
      _HomeSubPage(
        title: "我",
        showTitle: false,
        icon: ("assets/images/tabbar/icons_outlined_me.svg"),
        activeIcon: ("assets/images/tabbar/icons_filled_me.svg"),
        page: MinePage(),
      ),
    ]);

    var w = ew(56);
    for (int i = 0; i < _pages.length; i++) {
      _HomeSubPage sub = _pages[i];
      bars.add(
        BottomNavigationBarItem(
          icon: Stack(
            alignment: Alignment.topRight,
            children: <Widget>[
              Padding(
                padding: EdgeInsets.only(bottom: ew(4)),
                child: SvgPicture.asset(sub.icon, width: w, height: w),
              ),
              Container(
                width: ew(20),
                height: ew(20),
                decoration:
                    BoxDecoration(color: Colors.red, shape: BoxShape.circle),
              )
            ],
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

    return AbsorbPointer(
      absorbing: _loading,
      child: Material(
        child: Stack(
          children: <Widget>[
            Scaffold(
              appBar: _buildAppBar(context),
              body: body,
              bottomNavigationBar: bottomBar,
            ),
            MenuWidget(
                key: _menuKey,
                menus: <MenuItem>[
                  MenuItem("add_group_chat",
                      "assets/images/contacts/icons_filled_chats.svg", "发起群聊"),
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
    );
  }

  _buildAppBar(BuildContext context) {
    var tab = HomeProvider.of(context, listen: false).tab;
    var title = _pages[tab].title;
    if (!_pages[tab].showTitle) return null;
    return PreferredSize(
      child: AppBar(
        centerTitle: false,
        elevation: 0,
        title: Row(
          children: <Widget>[
            Text(title, style: TextStyle(fontSize: sp(34))),
            Offstage(
              offstage: !_loading,
              child: Rotation(
                child: Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: ew(10), vertical: ew(10)),
                  child: SvgPicture.asset("assets/images/icons/loading.svg",
                      width: ew(32), height: ew(32), color: Colors.grey),
                ),
              ),
            )
          ],
        ),
        actions: <Widget>[
          IconButton(
            icon: SvgPicture.asset(
              'assets/images/icons/icons_outlined_add2.svg',
              color: Color(0xFF181818),
            ),
            onPressed: () {
              _menuKey.currentState.visible = true;
            },
          )
        ],
      ),
      preferredSize: Size.fromHeight(ew(80)),
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
