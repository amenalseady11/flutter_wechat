import 'package:audioplayers/audioplayers.dart';
import 'package:common_utils/common_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_wechat/pages/chat/widgets/app_bar.dart';
import 'package:flutter_wechat/pages/chat/widgets/bottom_bar.dart';
import 'package:flutter_wechat/pages/chat/widgets/message.dart';
import 'package:flutter_wechat/providers/chat/chat.dart';
import 'package:flutter_wechat/providers/chat_message/chat_message.dart';
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
      var chat = ChatProvider.of(context, listen: false);
      chat.group?.remoteUpdate(context);

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
                LogUtil.v("消息总条数：" + length.toString(), tag: "###ChagePage###");
                return _buildChild(context, length);
              },
            ),
          ),
          ChatBottomBar()
        ],
      ),
    );
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: widget.chat),
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
          if (index <= 0) return Container();
          var prev = widget.chat.messages[index];
          var next = widget.chat.messages[index + 1];
          var duration = next.sendTime.difference(prev.sendTime);
          if (duration.inMinutes < 5) return Container();
          duration = DateTime.now().difference(next.sendTime);

          var hour = next.sendTime.hour;
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
            text = DateUtil.formatDate(next.sendTime, format: "$hours HH:mm");
          else if (days < 2)
            text =
                DateUtil.formatDate(next.sendTime, format: "昨天 $hours HH:mm");
          else if (days < 7)
            text = DateUtil.getZHWeekDay(next.sendTime).substring(2) +
                DateUtil.formatDate(next.sendTime, format: " $hours HH:mm");
          else if (next.sendTime.year == DateTime.now().year)
            text = DateUtil.formatDate(next.sendTime,
                format: "MM月dd日 $hours HH:mm");
          else
            text = DateUtil.formatDate(next.sendTime,
                format: "yyyy年MM月dd $hours HH:mm");
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

      LogUtil.v("长度:${list.length}", tag: "### ChatPage ###");
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
