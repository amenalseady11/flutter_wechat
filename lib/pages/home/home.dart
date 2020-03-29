import 'dart:io';

import 'package:common_utils/common_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_wechat/global/global.dart';
import 'package:flutter_wechat/pages/chat/chats.dart';
import 'package:flutter_wechat/pages/contact/contacts.dart';
import 'package:flutter_wechat/pages/discover/discover.dart';
import 'package:flutter_wechat/pages/mine/mine.dart';
import 'package:flutter_wechat/pages/mine/qr_code_scan.dart';
import 'package:flutter_wechat/providers/chat/chat.dart';
import 'package:flutter_wechat/providers/chat/chat_list.dart';
import 'package:flutter_wechat/providers/chat_message/chat_message.dart';
import 'package:flutter_wechat/providers/contact/contact.dart';
import 'package:flutter_wechat/providers/contact/contact_list.dart';
import 'package:flutter_wechat/providers/group/group.dart';
import 'package:flutter_wechat/providers/group/group_list.dart';
import 'package:flutter_wechat/providers/home/home.dart';
import 'package:flutter_wechat/providers/sqflite/sqflite.dart';
import 'package:flutter_wechat/routers/routers.dart';
import 'package:flutter_wechat/socket/socket.dart';
import 'package:flutter_wechat/util/adapter/adapter.dart';
import 'package:flutter_wechat/util/dialog/dialog.dart';
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

  bool _loading = true;

  _remoteUpdate() async {
    var updates = await Future.wait([
      Provider.of<ContactListProvider>(context, listen: false)
          .remoteUpdate(context),
      Provider.of<GroupListProvider>(context, listen: false)
          .remoteUpdate(context),
    ]);
    if (updates.contains(false) &&
        await confirm(context, content: "网络连接失败，是否重试?", okText: "重试")) {
      this._remoteUpdate();
    }
  }

  void _initData() async {
    if (socket.started) {
      _loading = false;
      return;
    }

    await Future.microtask(() {});

    if (global.isDevelopment) {
      var database = await SqfliteProvider().connect();
      await Future.wait([
        database.delete(ChatProvider.tableName),
        database.delete(ChatMessageProvider.tableName),
        database.delete(ContactProvider.tableName),
        database.delete(GroupProvider.tableName),
      ]);
    }

    await Future.wait([
      Provider.of<GroupListProvider>(context, listen: false).deserialize(),
      Provider.of<ContactListProvider>(context, listen: false).deserialize(),
    ]);

    await this._remoteUpdate();

    await Provider.of<ChatListProvider>(context, listen: false).deserialize();

    var chats = Provider.of<ChatListProvider>(context, listen: false).map;
    var contacts =
        Provider.of<ContactListProvider>(context, listen: false).contacts;
    var groups = Provider.of<GroupListProvider>(context, listen: false).groups;

    for (ContactProvider contact in contacts) {
      ChatProvider chat = chats[contact.friendId];
      if (chat != null) {
        chat.contact = contact;
        continue;
      }
      chat = ChatProvider(
        profileId: global.profile.profileId,
        sourceType: ChatSourceType.contact,
        sourceId: contact.friendId,
        latestUpdateTime: DateTime(2020, 2, 1),
        visible: false,
      )..contact = contact;
      await chat.serialize(forceUpdate: true);
      Provider.of<ChatListProvider>(context, listen: false).chats.add(chat);
    }

    Map<String, List<GroupProvider>> maps = {};
    for (GroupProvider group in groups) {
      ChatProvider chat = chats[group.groupId];
      if (chat != null) {
        chat.group = group;
        continue;
      }
      chat = ChatProvider(
        profileId: global.profile.profileId,
        sourceType: ChatSourceType.group,
        sourceId: group.groupId,
        latestUpdateTime: DateTime(2020, 2, 1),
        visible: false,
      )..group = group;
      await chat.serialize(forceUpdate: true);
      Provider.of<ChatListProvider>(context, listen: false).chats.add(chat);

      if (!maps.containsKey(group.groupId))
        maps.putIfAbsent(group.groupId, () => []);
      maps[group.groupId].add(group);
    }
    var clp = Provider.of<ChatListProvider>(context, listen: false);
    LogUtil.v("话题列表：${clp.chats.length}", tag: "### HomePage ###");
    if (clp.chats.length > 0) clp.forceUpdate();

    socket.start();
    socket.create(
        private: true,
        sourceId: global.profile.profileId,
        getOffset: () => global.profile.offset);

    chats = Provider.of<ChatListProvider>(context, listen: false).map;
    for (GroupProvider group in groups) {
      var chat = chats[group.groupId];
      socket.create(
          private: false,
          sourceId: chat.sourceId,
          getOffset: () => chat.offset);
    }

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
