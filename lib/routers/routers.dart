import 'package:fluro/fluro.dart';
import 'package:flutter/material.dart';
import 'package:flutter_wechat/pages/chat/chat.dart';
import 'package:flutter_wechat/pages/chat/chat_gallery.dart';
import 'package:flutter_wechat/pages/chat/chat_set_contact.dart';
import 'package:flutter_wechat/pages/chat/chat_set_group.dart';
import 'package:flutter_wechat/pages/contact/add_contact.dart';
import 'package:flutter_wechat/pages/contact/add_contact_applies.dart';
import 'package:flutter_wechat/pages/contact/add_contact_apply.dart';
import 'package:flutter_wechat/pages/contact/add_contact_approve.dart';
import 'package:flutter_wechat/pages/contact/contact.dart';
import 'package:flutter_wechat/pages/contact/contact_set_remark.dart';
import 'package:flutter_wechat/pages/group/group_add_member.dart';
import 'package:flutter_wechat/pages/group/group_del_member.dart';
import 'package:flutter_wechat/pages/group/group_member_set_nickname.dart';
import 'package:flutter_wechat/pages/group/group_set_admin.dart';
import 'package:flutter_wechat/pages/group/group_set_announcement.dart';
import 'package:flutter_wechat/pages/group/group_set_forbidden.dart';
import 'package:flutter_wechat/pages/group/group_set_name.dart';
import 'package:flutter_wechat/pages/group/groups.dart';
import 'package:flutter_wechat/pages/home/home.dart';
import 'package:flutter_wechat/pages/login/login.dart';
import 'package:flutter_wechat/pages/login/login_phone.dart';
import 'package:flutter_wechat/pages/mine/about.dart';
import 'package:flutter_wechat/pages/mine/account_security.dart';
import 'package:flutter_wechat/pages/mine/avatar.dart';
import 'package:flutter_wechat/pages/mine/message_notice.dart';
import 'package:flutter_wechat/pages/mine/network_diagnosis.dart';
import 'package:flutter_wechat/pages/mine/privacy_settings.dart';
import 'package:flutter_wechat/pages/mine/qr_code.dart';
import 'package:flutter_wechat/pages/mine/qr_code_scan.dart';
import 'package:flutter_wechat/pages/mine/set_nickname.dart';
import 'package:flutter_wechat/pages/mine/settings.dart';
import 'package:flutter_wechat/pages/root/root.dart';
import 'package:flutter_wechat/pages/splash/splash.dart';
import 'package:flutter_wechat/pages/web_view/web_view.dart';
import 'package:flutter_wechat/providers/chat/chat.dart';
import 'package:flutter_wechat/providers/chat/chat_list.dart';
import 'package:flutter_wechat/providers/contact/contact_list.dart';
import 'package:flutter_wechat/providers/group/group_list.dart';
import 'package:flutter_wechat/providers/home/home.dart';

export 'package:fluro/fluro.dart';

class Routers {
  /// 根
  static const String root = "/";

  /// 登录
  static const String login = "/login";

  /// 手机登录
  static const String loginPhone = "/login_phone";

  /// 主页
  static const String home = "/home";

  /// 主页 - 聊天列表
  static const String homeChats = "/home_chats";

  /// 主页 - 联系人列表
  static const String homeContacts = "/home_contacts";

  /// 主页 - 发现页面
  static const String homeDiscover = "/home_discover";

  /// 主页 - 我的页面
  static const String homeMime = "/home_mime";

  /// 网页
  static const String webView = "/web_view";

  /// 联系人明细
  static const String contact = "/contact";

  /// 聊天
  static const String chat = "/chat";

  /// 聊天相册预览
  static const String chatGallery = "/chat_gallery";

  /// 群聊设置
  static String chatSetGroup = "/chat_set_group";

  /// 私聊设置
  static String chatSetContact = "/chat_set_contact";

  /// 添加朋友
  static const String addContact = "/add_contact";

  /// 申请添加朋友
  static const String addContactApply = "/add_contact_apply";

  /// 申请添加朋友列表
  static const String addContactApplies = "/add_contact_applies";

  /// 验证新朋友
  static const String addContactApprove = "/add_contact_approve";

  /// 设置备注
  static const String contactSetRemark = "/contact_set_remark";

  /// 头像
  static String avatar = "/avatar";

  /// 设置
  static String settings = "/settings";

  /// 隐私设置
  static String privacySettings = "/privacy_settings";

  /// 安全
  static String accountSecurity = "/account_security";

  /// 关于
  static String about = "/about";

  /// 网络诊断
  static String networkDiagnosis = "/network_diagnosis";

  /// 消息通知
  static String messageNotice = "/message_notice";

  /// 设置昵称
  static String setNickname = "/set_nickname";

  /// 二维码
  static String qrCode = "/qr_code";

  /// 二维码扫描
  static String qrCodeScan = "/qr_code_scan";

  /// 群聊列表
  static String groups = "/groups";

  /// 发起群聊/批量添加群聊成员
  static String groupAddMember = "/group_add_member";

  /// 踢出群组成员员
  static String groupDelMember = "/group_del_member";

  /// 群昵称
  static String groupMemberSetNickname = "/group_member_nickname";

  /// 群聊名称
  static String groupSetName = "/group_set_name";

  /// 群公告
  static String groupSetAnnouncement = "/group_set_announcement";

  /// 设置群主与管理员
  static String groupSetAdmin = "/group_set_admin";

  /// 设置群聊禁言
  static String groupSetForbidden = "/group_set_forbidden";

  static navigateTo(BuildContext context, String path,
      {bool replace = false,
      bool clearStack = false,
      TransitionType transition,
      Duration transitionDuration = const Duration(milliseconds: 250),
      RouteTransitionsBuilder transitionBuilder}) {
    return Router.appRouter.navigateTo(context, path,
        replace: replace,
        clearStack: clearStack,
        transitionDuration: transitionDuration,
        transitionBuilder: transitionBuilder);
  }

  static Route<dynamic> generator(RouteSettings routeSettings) {
    return Router.appRouter.generator(routeSettings);
  }

  static void configureRoutes({bool isUpgrade = false}) {
    Router router = Router.appRouter;

    router.define(root,
        handler: Handler(
            handlerFunc: (context, params) =>
                isUpgrade ? SplashPage() : RootPage()));

    router.define(login,
        transitionType: TransitionType.fadeIn,
        handler: Handler(handlerFunc: (context, params) => LoginPage()));

    router.define(loginPhone,
        handler: Handler(handlerFunc: (context, params) => LoginPhonePage()));

    router.define(home, handler: Handler(handlerFunc: (context, params) {
      var tab = params["tab"]?.first;
      if (tab == "chats")
        HomeProvider.of(context, listen: false).tab = 0;
      else if (tab == "concats")
        HomeProvider.of(context, listen: false).tab = 1;
      else if (tab == "discover")
        HomeProvider.of(context, listen: false).tab = 2;
      else if (tab == "mime") HomeProvider.of(context, listen: false).tab = 3;

      return HomePage();
    }));

    router.define(webView, transitionType: TransitionType.inFromRight,
        handler: Handler(handlerFunc: (context, params) {
      return WebViewPage(
        title: params["title"]?.first,
        url: params["url"]?.first,
      );
    }));

    router.define(contact, transitionType: TransitionType.inFromRight,
        handler: Handler(handlerFunc: (context, params) {
      return ContactPage.fromFriend(
        context,
        groupId: params["groupId"]?.first,
        friendId: params["friendId"]?.first,
      );
    }));

    router.define(contactSetRemark, transitionType: TransitionType.inFromRight,
        handler: Handler(handlerFunc: (context, params) {
      return ContactSetRemark(
        friendId: params["friendId"]?.first,
        remark: params["remark"]?.first,
      );
    }));

    router.define(chat, transitionType: TransitionType.inFromRight,
        handler: Handler(handlerFunc: (context, params) {
      if (params["sourceType"]?.first == null ||
          params["sourceId"]?.first == null) {
        Future.microtask(() {
          Navigator.pop(context);
        });
        return Scaffold(body: Center(child: Text("错误参数")));
      }
      int sourceType = params["sourceType"]?.first == "0" ? 0 : 1;
      String sourceId = params["sourceId"]?.first;

      var clp = ChatListProvider.of(context, listen: false);
      if (!clp.map.containsKey(sourceId)) {
        ChatProvider chat = ChatProvider(
            sourceType: sourceType,
            sourceId: sourceId,
            latestUpdateTime: DateTime.now())
          ..serialize();
        if (sourceType == 0)
          chat.contact =
              ContactListProvider.of(context, listen: false).map[sourceId];
        else if (sourceType == 1)
          chat.group =
              GroupListProvider.of(context, listen: false).map[sourceId];
        clp.chats.insert(0, chat);
      }

      return ChatPage(chat: clp.map[sourceId]);
    }));

    router.define(chatGallery,
        transitionType: TransitionType.fadeIn,
        handler: Handler(
            handlerFunc: (context, params) => ChatGalleryPage(
                  sourceId: params['sourceId']?.first,
                  sendId: params['sendId']?.first,
                )));

    router.define(chatSetGroup,
        transitionType: TransitionType.inFromRight,
        handler: Handler(
            handlerFunc: (context, params) =>
                ChatSetGroupPage(groupId: params['groupId']?.first)));

    router.define(chatSetContact,
        transitionType: TransitionType.inFromRight,
        handler: Handler(
            handlerFunc: (context, params) =>
                ChatSetContactPage(friendId: params['friendId']?.first)));

    router.define(groups,
        transitionType: TransitionType.inFromRight,
        handler: Handler(handlerFunc: (context, params) => GroupsPage()));

    router.define(groupAddMember,
        transitionType: TransitionType.inFromRight,
        handler: Handler(
            handlerFunc: (context, params) =>
                GroupAddMemberPage(groupId: params['groupId']?.first)));

    router.define(groupDelMember,
        transitionType: TransitionType.inFromRight,
        handler: Handler(
            handlerFunc: (context, params) =>
                GroupDelMemberPage(groupId: params['groupId']?.first)));

    router.define(groupMemberSetNickname,
        transitionType: TransitionType.inFromRight,
        handler: Handler(
            handlerFunc: (context, params) => GroupMemberSetNicknamePage(
                nickname: params['nickname']?.first)));

    router.define(groupSetName,
        transitionType: TransitionType.inFromRight,
        handler: Handler(
            handlerFunc: (context, params) =>
                GroupSetNamePage(name: params['name']?.first)));

    router.define(groupSetAnnouncement,
        transitionType: TransitionType.inFromRight,
        handler: Handler(
            handlerFunc: (context, params) => GroupSetAnnouncementPage(
                announcement: params['announcement']?.first)));

    router.define(groupSetAdmin,
        transitionType: TransitionType.inFromRight,
        handler: Handler(
            handlerFunc: (context, params) =>
                GroupSetAdminPage(groupId: params['groupId']?.first)));

    router.define(groupSetForbidden,
        transitionType: TransitionType.inFromRight,
        handler: Handler(
            handlerFunc: (context, params) =>
                GroupSetForbiddenPage(groupId: params['groupId']?.first)));

    router.define(addContact,
        transitionType: TransitionType.inFromRight,
        handler: Handler(handlerFunc: (context, params) => AddContactPage()));

    router.define(addContactApply,
        transitionType: TransitionType.inFromRight,
        handler: Handler(
            handlerFunc: (context, params) =>
                AddContactApplyPage(friendId: params['friendId']?.first)));

    router.define(addContactApplies,
        transitionType: TransitionType.inFromRight,
        handler:
            Handler(handlerFunc: (context, params) => AddContactAppliesPage()));

    router.define(addContactApprove,
        transitionType: TransitionType.inFromRight,
        handler: Handler(
            handlerFunc: (context, params) =>
                AddContactApprovePage(friendId: params['friendId']?.first)));

    router.define(avatar,
        transitionType: TransitionType.inFromRight,
        handler: Handler(handlerFunc: (context, params) => AvatarPage()));

    router.define(setNickname,
        transitionType: TransitionType.inFromRight,
        handler: Handler(handlerFunc: (context, params) => SetNicknamePage()));

    router.define(qrCode,
        transitionType: TransitionType.inFromRight,
        handler: Handler(handlerFunc: (context, params) => QrCodePage()));

    router.define(qrCodeScan,
        transitionType: TransitionType.fadeIn,
        handler: Handler(handlerFunc: (context, params) => QrCodeScanPage()));

    router.define(messageNotice,
        transitionType: TransitionType.inFromRight,
        handler:
            Handler(handlerFunc: (context, params) => MessageNoticePage()));

    router.define(accountSecurity,
        transitionType: TransitionType.inFromRight,
        handler:
            Handler(handlerFunc: (context, params) => AccountSecurityPage()));

    router.define(settings,
        transitionType: TransitionType.inFromRight,
        handler: Handler(handlerFunc: (context, params) => SettingsPage()));

    router.define(privacySettings,
        transitionType: TransitionType.inFromRight,
        handler:
            Handler(handlerFunc: (context, params) => PrivacySettingsPage()));

    router.define(about,
        transitionType: TransitionType.inFromRight,
        handler: Handler(handlerFunc: (context, params) => AboutPage()));

    router.define(networkDiagnosis,
        transitionType: TransitionType.inFromRight,
        handler:
            Handler(handlerFunc: (context, params) => NetworkDiagnosisPage()));
  }
}
