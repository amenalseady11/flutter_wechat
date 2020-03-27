import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:common_utils/common_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_wechat/apis/apis.dart';
import 'package:flutter_wechat/global/global.dart';
import 'package:flutter_wechat/providers/chat/chat.dart';
import 'package:flutter_wechat/providers/chat/chat_list.dart';
import 'package:flutter_wechat/providers/chat_message/chat_message.dart';
import 'package:flutter_wechat/providers/sqflite/sqflite.dart';

enum SocketChannelEnum { creating, connecting, error }

class SocketChannel {
  final StreamController<SocketChannelEnum> state;

  const SocketChannel(this.state);
}

// todo: 1. 待实现连接失败
// todo: 2. 待实现连接成功后，中途断链，重连机制
class _HttpSocket {
  final Map<String, SocketChannel> _sockets = {};
  Map<String, SocketChannel> get sockets => _sockets;

  final HttpClient _client;
  _HttpSocket._(HttpClient client)
      : _client = client,
        super();

  HttpClient get http => _client;

  StreamController<ChatMessageProvider> messages = StreamController();

  factory _HttpSocket() {
    return _HttpSocket._(HttpClient());
  }

  create(
      {@required bool private,
      @required String sourceId,
      @required Function getOffset}) async {
    assert(private != null);
    assert(sourceId != null);
    assert(getOffset != null);

    String socketKey = private ? "/topic/private" : "/topic/group/$sourceId";
    if (_sockets.containsKey(socketKey)) return;
    var ctl = SocketChannel(StreamController());
    ctl.state.add(SocketChannelEnum.creating);
    _sockets.putIfAbsent(socketKey, () => ctl);

    int offset1 = getOffset() ?? 0;
    var database = await SqfliteProvider().connect();
    var sql = private
        ? "select max(offset) as offset from ${ChatProvider.tableName} where profileId = '${global.profile.profileId}' and sourceType = 0"
        : "select max(offset) as offset from ${ChatProvider.tableName} where profileId = '${global.profile.profileId}' and sourceId = '$sourceId'";
    if (global.isDebug) LogUtil.v(sql, tag: "### Socket ###");
    var list = await database.rawQuery(sql) ?? [];

    int offset2 = list.first['offset'] ?? 0;

    var offset = offset1 >= offset2 ? offset1 : offset2;
    if (offset == 0) {
      var rsp = await toGetTopicOffset(
          sourceId: private ? global.profile.friendId : sourceId);
      if (rsp.success) offset = rsp.body as int ?? 0;
    }

    if (global.isDebug)
      LogUtil.v("创建连接:(${private ? '私' : '群'})$socketKey?offset=$offset 开始",
          tag: "### Socket ###");

    var url = "${global.apiBaseUrl}$socketKey?offset=$offset";

    /// 创建请求
    HttpClientRequest request = await http.getUrl(Uri.parse(url));

    // 设置接收字符串
    request.headers.removeAll(HttpHeaders.acceptEncodingHeader);

    // 设置请求的 header
    if (global.profile?.authToken != null)
      request.headers.add("AUTH_TOKEN", global.profile?.authToken);

    // 等待连接服务器
    HttpClientResponse response = await request.close();

    if (response.statusCode != HttpStatus.ok) {
      if (global.isDebug)
        LogUtil.v(
            "创建连接:(${private ? '私' : '群'})$socketKey 失败：${response.statusCode}",
            tag: "### Socket ###");
      ctl.state.add(SocketChannelEnum.error);
      await Future.delayed(Duration(milliseconds: 1000));
      return create(private: private, sourceId: sourceId, getOffset: getOffset);
    }

    if (global.isDebug)
      LogUtil.v("创建连接:(${private ? '私' : '群'})$socketKey 成功",
          tag: "### Socket ###");

    ctl.state.add(SocketChannelEnum.connecting);

    Map<String, Future<ChatProvider>> locks = {};

    var stream = response.transform<String>(utf8.decoder);

    // ignore: cancel_subscriptions
    var subscription;
    subscription = stream.listen(
      (jsonStr) async {
        if (subscription != null && !global.profile.isLogged) {
          if (global.isDebug)
            LogUtil.v("取消订阅(${private ? '私' : '群'}[$sourceId])",
                tag: "### Socket ###");
          return subscription.cancel();
        }

        Map<String, dynamic> json;
        try {
          json = jsonDecode(jsonStr);
        } catch (e) {
          if (global.isDebug)
            LogUtil.v("解析消息流异常(${private ? '私' : '群'}[$sourceId]):",
                tag: "### Socket ###");
          if (global.isDebug)
            LogUtil.v("解析消息流文本(${private ? '私' : '群'}[$sourceId]): $jsonStr",
                tag: "### Socket ###");
          LogUtil.e(e);
          return;
        }
        String contentType = json["ContentType"];
        int offset = json["Offset"] as int;
        if (MessageType.heartbeat == contentType) {
          if (global.isDebug)
            LogUtil.v(
                "收到消息:${private ? '私' : '群'}[$sourceId]心跳包 " +
                    DateTime.now().toString(),
                tag: "### Socket ###");
          return;
        }

        ChatMessageProvider message;
        if (contentType == MessageType.text)
          message = ChatMessageProvider(status: ChatMessageStatusEnum.complete);
        else if (contentType == MessageType.urlImg)
          message = ChatMessageProvider(status: ChatMessageStatusEnum.loading);
        else if (contentType == MessageType.urlVoice)
          message = ChatMessageProvider(
              status: ChatMessageStatusEnum.loading,
              state: ChatMessageStates.voiceUnRead);
        else {
          if (global.isDebug)
            LogUtil.v("收到消息:${private ? '私' : '群'}[$sourceId]$contentType-暂不支持",
                tag: "### Socket ###");
          return;
        }

        if (message == null || !global.profile.isLogged) return;

        message
          ..profileId = global.profile.profileId
          ..sourceId = sourceId
          ..sendId = global.uuid
          ..sendTime =
              DateTime.fromMillisecondsSinceEpoch(json["SendTime"] as int)
          ..type = contentType
          ..body = json["Body"] as String ?? ""
          ..fromFriendId = json["FormId"] ?? ""
          ..fromNickname = json['NickName'] ?? ""
          ..fromAvatar = json["Avatar"] ?? ""
          ..offset = json["Offset"] as int ?? -1;

        if (private) {
          message.sourceId = message.fromFriendId;
          message.toFriendId = global.profile.friendId;
        }

        ChatProvider chat;
        Completer<ChatProvider> completer;
        if (locks.containsKey(message.sourceId)) {
          chat = await locks[message.sourceId];
        }
        var clp = ChatListProvider();
        if (chat == null) {
          chat = clp.getChat(
              sourceType:
                  private ? ChatSourceType.contact : ChatSourceType.group,
              sourceId: message.sourceId);

          if (chat?.serializeId == null) {
            completer = Completer();
            locks.putIfAbsent(message.sourceId, () => completer.future);
            chat = await clp.getChatAsync(
                sourceType:
                    private ? ChatSourceType.contact : ChatSourceType.group,
                sourceId: message.sourceId);
          }
        }

        await chat.addMessage(message);
        if (completer != null) {
          clp.addChat(chat, sort: true, forceUpdate: true);
          completer.complete(chat);
        }
        clp.sort(forceUpdate: true);
        if (global.isDebug) {
          LogUtil.v(
              "\n收到消息:${private ? '私' : '群'}[$sourceId]$contentType(offset:$offset)：${DateUtil.formatDate(message.sendTime)}\n${message.toJson().toString()}\n\n",
              tag: "### Socket ###");
        }
        return;
      },
      cancelOnError: true,
    );
    return;
  }

  /// 暂时还没有实现
  remove(String sourceId, {bool private = false}) {}

  dispose() {
    messages.close();
    http.close(force: true);
  }
}

class SocketUtil {
  _HttpSocket _socket;

  start() => restart();

  restart() {
    if (this._socket != null) this.stop();
    this._socket = _HttpSocket();
  }

  /// 创建长连接
  /// [private] 是否是私有话题
  /// [sourceId] 话题编号
  /// [getOffset] 话题初始偏移量
  Future create(
      {@required bool private,
      @required String sourceId,
      @required Function getOffset}) {
    return _socket.create(
        private: private, sourceId: sourceId, getOffset: getOffset);
  }

  dispose() => stop();

  stop() {
    if (this._socket == null) return;
    this._socket.dispose();
    this._socket = null;
  }
}

var socket = SocketUtil();
