import 'package:audioplayers/audioplayers.dart';
import 'package:common_utils/common_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_wechat/pages/chat/widgets/app_bar.dart';
import 'package:flutter_wechat/pages/chat/widgets/bottom_bar.dart';
import 'package:flutter_wechat/pages/chat/widgets/message.dart';
import 'package:flutter_wechat/providers/chat/chat.dart';
import 'package:flutter_wechat/providers/chat_message/chat_message.dart';
import 'package:flutter_wechat/providers/contact/contact.dart';
import 'package:flutter_wechat/providers/group/group.dart';
import 'package:flutter_wechat/providers/sqflite/sqflite.dart';
import 'package:flutter_wechat/util/adapter/adapter.dart';
import 'package:flutter_wechat/util/style/style.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class ChatPage extends StatefulWidget {
  final ChatProvider chat;
  const ChatPage({Key key, @required this.chat})
      : assert(chat != null),
        super(key: key);

  @override
  ChatPageState createState() => ChatPageState();
}

class ChatPageState extends State<ChatPage> {
  static ChatPageState of(BuildContext context, {bool listen = true}) {
    return Provider.of<ChatPageState>(context, listen: listen);
  }

  AudioPlayer audio = AudioPlayer(playerId: "chat_auido_player");

  ScrollController scroller = ScrollController();
  RefreshController _refreshController =
      RefreshController(initialRefresh: false);

  @override
  void initState() {
    super.initState();

    Future.microtask(() async {
      widget.chat.group?.remoteUpdate(context);

      await this._onRefresh();

      /// 激活状态，保证监听的消息，持续化消息，同时必须添加到消息列表中
      widget.chat.activating = true;
    });

    if (widget.chat.unreadTag || widget.chat.unread > 0) {
      widget.chat.unreadTag = false;
      widget.chat.unread = 0;
      widget.chat.serialize(forceUpdate: true);
    }
  }

  @override
  void dispose() {
    widget.chat.activating = false;
    widget.chat.messages.clear();

    Future.microtask(() async {
      await audio.stop();
      audio.dispose();
    });
    super.dispose();
  }

  Future<void> toScrollEnd(
      {Future delay,
      Duration duration = const Duration(milliseconds: 300)}) async {
    if (delay != null) await delay;
    return scroller.animateTo(scroller.position.maxScrollExtent,
        duration: duration, curve: Curves.ease);
  }

  @override
  Widget build(BuildContext context) {
    var child = Scaffold(
      backgroundColor: Style.pBackgroundColor,
      appBar: ChatAppBar(),
      body: Column(
        children: <Widget>[
          Expanded(
            flex: 2,
            child: Selector<ChatProvider, int>(
              selector: (context, chat) {
                return chat.messages.length;
              },
              builder: (context, length, child) {
                return _buildChild(context, length);
              },
            ),
          ),
          Selector2<GroupProvider, ContactProvider, String>(
            selector: (context, group, contact) {
              if (group?.status == GroupStatus.dismiss)
                return "群组已解散";
              else if (group?.status == GroupStatus.exited)
                return "你已踢出群组";
              else if (group?.forbidden == GroupForbiddenStatus.forbidden)
                return "全体禁言";
//              else if (group?.self?.forbidden == GroupForbiddenStatus.forbidden)
//                return "你已被禁言";

              if (contact?.status == ContactStatus.notFriend)
                return "对方不是你好友";
              else if (contact?.black == ContactBlackStatus.black)
                return "黑名单";
              else if (contact?.black == ContactBlackStatus.eachBlack)
                return "黑名单";

              return null;
            },
            builder: (context, text, child) {
              if (text == null) return ChatBottomBar();
              return Stack(children: <Widget>[
                ChatBottomBar(),
                Opacity(
                  opacity: 0.5,
                  child: Container(
                    color: Colors.grey,
                    width: double.maxFinite,
                    height: ew(110),
//                    decoration: BoxDecoration(),
                  ),
                ),
                Container(
                    height: ew(110),
                    child: Center(
                        child: Text(text,
                            style: TextStyle(
                                fontSize: ew(32), color: Style.sTextColor)))),
              ]);
            },
          )
        ],
      ),
    );
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: widget.chat),
        ChangeNotifierProvider.value(value: widget.chat.group),
        ChangeNotifierProvider.value(value: widget.chat.contact),
        Provider.value(value: audio),
        Provider.value(value: this),
      ],
      child: child,
    );
  }

  Widget _buildChild(BuildContext context, int length) {
    return SmartRefresher(
      controller: _refreshController,
      header: CustomHeader(builder: (context, mode) {
        return Center(
            child: Text("加载中...", style: TextStyle(color: Style.sTextColor)));
      }),
      onRefresh: _onRefresh,
      child: ListView.separated(
        physics: ClampingScrollPhysics(),
        controller: scroller,
        itemCount: length,
        itemBuilder: (context, index) {
          var message = widget.chat.messages[index];
          return ChangeNotifierProvider.value(
            value: message,
            child: Consumer<ChatMessageProvider>(
              builder: (context, message, child) {
                return ChatMessage(
                    key: ValueKey(message.sendId), message: message);
              },
            ),
          );
        },
        separatorBuilder: (BuildContext context, int index) {
          var current = widget.chat.messages[index + 1].sendTime;
          var next = widget.chat.messages.length > index + 2
              ? widget.chat.messages[index + 2].sendTime
              : DateTime.now();
          var duration = next.difference(current);
          if (duration.inMinutes < 5) return Container();
          duration = DateTime.now().difference(current);

          var hour = current.hour;
          var hours;
          if (hour < 6)
            hours = "凌晨";
          else if (hour < 8)
            hours = "早上";
          else if (hour < 11)
            hours = "上午";
          else if (hour < 14)
            hours = "中午";
          else if (hour < 18)
            hours = "下午";
          else if (hour < 20)
            hours = "傍晚";
          else if (hour < 24) hours = "晚上";

          var text;
          var days = duration.inDays;
          if (days < 1)
            text = DateUtil.formatDate(current, format: "$hours HH:mm");
          else if (days < 2)
            text = DateUtil.formatDate(current, format: "昨天 $hours HH:mm");
          else if (days < 7)
            text = DateUtil.getZHWeekDay(current).replaceFirst("星期", "周") +
                DateUtil.formatDate(current, format: " $hours HH:mm");
          else if (current.year == DateTime.now().year)
            text = DateUtil.formatDate(current, format: "MM月dd日 $hours HH:mm");
          else
            text =
                DateUtil.formatDate(current, format: "yyyy年MM月dd $hours HH:mm");
          return Container(
            padding: EdgeInsets.symmetric(vertical: ew(10)),
            child: Text(text,
                textAlign: TextAlign.center,
                style: TextStyle(color: Style.sTextColor, fontSize: sp(24))),
          );
        },
      ),
    );
  }

  _onRefresh() async {
    var database = await SqfliteProvider().connect();
    var chat = widget.chat;
    var list;
    var limit = 15;
    try {
      if (chat.messages.isEmpty) {
        list = await database.query(ChatMessageProvider.tableName,
            where: "profileId = ? and sourceId = ? ",
            whereArgs: [chat.profileId, chat.sourceId],
            orderBy: "serializeId desc",
            limit: limit,
            offset: 0);
      } else {
        list = await database.query(ChatMessageProvider.tableName,
            where: "profileId = ? and sourceId = ? and serializeId < ?",
            whereArgs: [
              chat.profileId,
              chat.sourceId,
              chat.messages.first.serializeId
            ],
            orderBy: "serializeId desc",
            limit: limit,
            offset: 0);
      }

      LogUtil.v("本次加载条数:${list.length}", tag: "### ChatPage ###");
      for (var json in list) {
        var message = ChatMessageProvider.fromJson(json);
        chat.messages.insert(0, message);
      }
      _refreshController.refreshCompleted();
      if (mounted && list.isNotEmpty) {
        setState(() {});
      }
    } catch (e) {
      _refreshController.refreshCompleted();
    }
  }
}
