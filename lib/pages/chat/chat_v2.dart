import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:common_utils/common_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_wechat/pages/chat/widgets/chat_app_bar.dart';
import 'package:flutter_wechat/pages/chat/widgets/chat_bottom_bar_wrapper.dart';
import 'package:flutter_wechat/pages/chat/widgets/chat_date_tip.dart';
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

  ScrollController _scrollController =
      ScrollController(keepScrollOffset: false);
  RefreshController _refreshController =
      RefreshController(initialRefresh: false);

  StreamSubscription _subscription;

  bool _loadAll = false;

  @override
  void initState() {
    super.initState();
    if (widget.chat.unreadTag || widget.chat.unread > 0) {
      widget.chat.unreadTag = false;
      widget.chat.unread = 0;
      widget.chat.serialize(forceUpdate: true);
    }

    Future.delayed(Duration(milliseconds: 100)).then((_) {
      this._onLoad();

      /// 激活状态，保证监听的消息，持续化消息，同时必须添加到消息列表中
      widget.chat.activating = true;
    });
  }

  @override
  void dispose() {
    widget.chat.activating = false;
    widget.chat.messages.clear();
    _subscription?.cancel();
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
    if (!mounted) return;
    return _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: duration,
        curve: Curves.ease);
  }

  @override
  Widget build(BuildContext context) {
    this.toScrollEnd(delay: Future.delayed(Duration(milliseconds: 500)));
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
          ChatBottomBarWrapper()
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
      child: GestureDetector(
          onTap: () {
            FocusScope.of(context).requestFocus(FocusNode());
          },
          child: child),
    );
  }

  Widget _buildChild(BuildContext context, int length) {
    return SmartRefresher(
      controller: _refreshController,
      header: CustomHeader(
          builder: (context, mode) => Center(
                  child: Container(
                padding: EdgeInsets.only(bottom: ew(10)),
                child: Text(_loadAll ? "--- 已到底了 ---" : "--- 历史记录 ---",
                    style:
                        TextStyle(color: Style.sTextColor, fontSize: ew(24))),
              ))),
      onRefresh: _onLoad,
      child: ListView.separated(
        controller: _scrollController,
        physics: ClampingScrollPhysics(),
        itemCount: length,
        itemBuilder: (context, index) {
          var message = widget.chat.messages[index];
          var child = ChangeNotifierProvider.value(
            value: message,
            child: Consumer<ChatMessageProvider>(
              builder: (context, message, child) {
                return ChatMessage(
                    key: ValueKey(message.sendId), message: message);
              },
            ),
          );

          if (index + 1 < length) return child;
          return Padding(
              padding: EdgeInsets.only(bottom: ew(60)), child: child);
        },
        separatorBuilder: (context, index) => ChatDateTip(index: index),
      ),
    );
  }

  _onLoad() async {
    var database = await SqfliteProvider().connect();
    var chat = widget.chat;
    var list;
    try {
      if (chat.messages.isEmpty) {
        list = await database.query(ChatMessageProvider.tableName,
            where: "profileId = ? and sourceId = ? ",
            whereArgs: [chat.profileId, chat.sourceId],
            orderBy: "serializeId desc",
            limit: 20,
            offset: 0);
        _loadAll = 20 > (list?.length ?? 0);
      } else {
        list = await database.query(ChatMessageProvider.tableName,
            where: "profileId = ? and sourceId = ? and serializeId < ?",
            whereArgs: [
              chat.profileId,
              chat.sourceId,
              chat.messages.first.serializeId
            ],
            orderBy: "serializeId desc",
            limit: 5,
            offset: 0);
        _loadAll = 5 > (list?.length ?? 0);
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
      _refreshController.refreshFailed();
    }
  }
}
