import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_wechat/global/global.dart';
import 'package:flutter_wechat/providers/chat/chat.dart';
import 'package:flutter_wechat/providers/chat/chat_list.dart';
import 'package:flutter_wechat/providers/chat_message/chat_message.dart';
import 'package:flutter_wechat/providers/group/group.dart';
import 'package:flutter_wechat/providers/group/group_list.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:common_utils/common_utils.dart';
import 'package:event_bus/event_bus.dart';
import 'package:flutter_wechat/apis/apis.dart';

class SocketMessageEvent {
  final String topic;
  final String message;
  const SocketMessageEvent(this.topic, this.message);
}

class SocketConnectorStateEvent {
  final String sourceId;
  final SocketConnectorState state;
  SocketConnectorStateEvent(this.sourceId, this.state);
}

EventBus _eventBus = EventBus();

final _tag = "### SocketService ###";

var dio = Dio(BaseOptions(connectTimeout: 0, receiveTimeout: 6000))
  ..interceptors.add(PrettyDioLogger(
    requestHeader: true,
    requestBody: false,
    responseBody: false,
    responseHeader: false,
    error: true,
    compact: true,
  ));

typedef int GetOffsetCallback();

enum SocketConnectorState {
  normal,
  opening,
  connecting,
  disconnect,
  error,
  close,
}

class SocketConnector {
  final bool private;
  final String sourceId;
  final String topic;
  final GetOffsetCallback getOffset;

  DateTime heartbeat;
  CancelToken _cancelToken;
  // ignore: cancel_subscriptions
  StreamSubscription _subscription;

  SocketConnectorState _state = SocketConnectorState.normal;
  set _setState(SocketConnectorState state) {
    if (state == this.state) return;
    this._state = state;
    _eventBus.fire(SocketConnectorStateEvent(sourceId, state));
  }

  SocketConnectorState get state => _state;
  CancelToken get cancelToken => _cancelToken;
  SocketConnector({this.private, this.sourceId, this.topic, this.getOffset});

  void reOpen() async {
    await this.close();
    return this.open();
  }

  void open([int retryCount = 0]) async {
    if (this.state == SocketConnectorState.opening) return;
    if (this.state == SocketConnectorState.connecting) return;
    if (this.state == SocketConnectorState.error) {
      var seconds = (retryCount / 10.0).ceil();
      await Future.delayed(Duration(seconds: max(seconds, 10)));
      LogUtil.v("$topic: 第 $retryCount 次重试-创建连接-开始", tag: _tag);
    }
    this._setState = SocketConnectorState.opening;
    this._cancelToken = CancelToken();

    var opts = RequestOptions(
        baseUrl: global.apiBaseUrl,
        cancelToken: cancelToken,
        responseType: ResponseType.stream,
        headers: {"AUTH_TOKEN": global.profile.authToken});
    if (retryCount == 0) LogUtil.v("$topic:创建连接-开始", tag: _tag);
    Response rsp;
    int offset = this.getOffset() ?? 0;
    if (offset == 0) {
      var rsp = await toGetTopicOffset(sourceId: sourceId);
      if (rsp.success) {
        offset = rsp.body as int ?? 0;
        if (private && offset > 0) {
          global.profile.offset = offset;
          global.profile.serialize();
        }
        var chat = ChatListProvider().map[this.sourceId];
        if (chat != null && offset > 0) {
          chat.offset = offset;
          chat.serialize();
        }
      }
    }
    try {
      rsp = await dio.get(this.topic,
          queryParameters: {"offset": offset}, options: opts);
    } catch (e) {}
    if (this.state == SocketConnectorState.close) return; // 已关闭，就不做处理了
    if (rsp?.statusCode != HttpStatus.ok) {
      this._setState = SocketConnectorState.error;
      return this.open(retryCount + 1);
    }
    if (rsp.data?.stream is! Stream) {
      this._setState = SocketConnectorState.error;
      return this.open(retryCount + 1);
    }

    retryCount > 0
        ? LogUtil.v("$topic: 第 $retryCount 次重试-创建连接-成功 $offset", tag: _tag)
        : LogUtil.v("$topic:创建连接-成功  $offset", tag: _tag);
    this._setState = SocketConnectorState.connecting;
    this.heartbeat = DateTime.now();
    var stream = rsp.data.stream as Stream;

    const CR = 13, LF = 10;
    List<int> bytes = [];
    var onData = (byteData) {
      this.heartbeat = DateTime.now();
      for (int byte in byteData) {
        if (byte != LF && byte != CR) {
          bytes.add(byte);
          continue;
        }
        if (bytes.isEmpty) continue;
        final message = utf8.decode(bytes);
        bytes.clear();
        _eventBus.fire(SocketMessageEvent(topic, message));
      }
    };
    var onError = ([dynamic error]) {
      this._setState = SocketConnectorState.error;
      return this.open(retryCount + 1);
    };
    var onDone = () {};

    _subscription = stream.listen(onData,
        onError: onError, onDone: onDone, cancelOnError: true);
  }

  close() {
    LogUtil.v("$topic:关闭连接-成功", tag: _tag);
    this._setState = SocketConnectorState.close;
    this._cancelToken?.cancel("客户端主动断开连接");
    this._subscription?.cancel();
  }
}

class SocketService {
  final Map<String, SocketConnector> _connectors = {};
  final Map<String, Future<ChatProvider>> _locks = {};

  SocketService._() {
    // 最大心跳等待时长秒数
    const maxWaitHeartbeatSeconds = 7000;
    // 每秒循环检查心跳数
    Timer.periodic(const Duration(seconds: 1), (_) {
      var connectors = this._connectors.values;
      var now = DateTime.now().millisecondsSinceEpoch;
      for (var connector in connectors) {
        if (connector.state != SocketConnectorState.connecting) continue;
        var diff = now - connector.heartbeat.millisecondsSinceEpoch;
        if (diff < maxWaitHeartbeatSeconds) continue;
        LogUtil.v("${connector.topic}: 超时$diff毫秒", tag: _tag);
        connector.reOpen();
      }
    });
  }

  bool get started => _connectors.length > 0;

  SocketConnectorState getSocketConnectorState(
      {@required bool private, @required String sourceId}) {
    var topic = private ? "/topic/private" : "/topic/group/$sourceId";
    var state = this._connectors[topic]?.state ?? SocketConnectorState.normal;
    return state;
  }

  listen(void onData(SocketMessageEvent event)) {
    return _eventBus.on<SocketMessageEvent>().listen(onData);
  }

  listenConnectorState(void onData(SocketConnectorStateEvent event)) {
    return _eventBus.on<SocketConnectorStateEvent>().listen(onData);
  }

  open(bool private, String sourceId, GetOffsetCallback getOffset) async {
    var topic = private ? "/topic/private" : "/topic/group/$sourceId";
    if (this._connectors.containsKey(topic)) return;
    var connector = SocketConnector(
        private: private,
        sourceId: sourceId,
        topic: topic,
        getOffset: getOffset);
    this._connectors.putIfAbsent(topic, () => connector);
    return connector.open();
  }

  close(bool private, String sourceId) {
    if (_locks.containsKey(sourceId)) _locks.remove(sourceId);
    var topic = private ? "/topic/private" : "/topic/group/$sourceId";
    this._connectors[topic]?.close();
  }

  closeAll() {
    this._locks.clear();
    this._connectors.values.forEach((d) => d.close());
    this._connectors.clear();
  }
}

final SocketService socket = SocketService._()
  ..listen((event) async {
    var connector = socket._connectors[event.topic];
    if (connector == null) return;

    final private = connector.private;
    final sourceId = connector.sourceId;

    if (!global.profile.isLogged) {
      if (global.isDebug)
        LogUtil.v("取消订阅(${private ? '私' : '群'}[$sourceId])", tag: _tag);
      return connector.close();
    }

    final jsonStr = event.message;

    Map<String, dynamic> json;
    try {
      json = jsonDecode(jsonStr);
    } catch (e) {
      if (global.isDebug) {
        LogUtil.v("解析消息流文本(${private ? '私' : '群'}[$sourceId])异常", tag: _tag);
        LogUtil.v(jsonStr, tag: _tag);
      }

      LogUtil.e(e, tag: _tag);
      return;
    }
    String contentType = json["ContentType"];

    if (MessageType.heartbeat == contentType) {
      if (global.isDebug)
        LogUtil.v(
            "收到消息:${private ? '私' : '群'}[$sourceId]心跳包 " +
                DateTime.now().toString(),
            tag: _tag);
      return;
    }

    if (MessageType.addFriend == contentType ||
        MessageType.addGroup == contentType ||
        MessageType.expelGroup == contentType ||
        MessageType.addGroupV2 == contentType) {
      var json2;
      try {
        json2 = jsonDecode(json['Body']);
        json["json2"] = json2;
      } catch (e) {
        if (global.isDebug)
          LogUtil.v(
              "解析 add friend message error(${private ? '私' : '群'}[$sourceId]): $jsonStr",
              tag: _tag);
        LogUtil.e(e, tag: _tag);
        return;
      }

      if (MessageType.addFriend == contentType) {
        // 不是同意添加好友通知，不处理
        if (json2["IsAgree"] != 11) return;
        json['FormId'] = json2['FriendID'];
        json['Body'] = "我们已是好友，可以开始聊天";
        json["SendTime"] = json["SendTime"] * 1000;
      } else if (MessageType.addGroup == contentType) {
        json['GroupID'] = json2['GroupID'];
        json['Body'] = "您已被邀请到群组，可以开始聊天了";
        json["SendTime"] = json["SendTime"] * 1000;
      } else if (MessageType.expelGroup == contentType) {
        json['GroupID'] = json2['GroupID'];
        json['Body'] = "您已被踢出群组";
        json["SendTime"] = json["SendTime"] * 1000;
      }
    }

    ChatMessageProvider message;

    if (contentType == MessageType.addFriend)
      message = ChatMessageProvider(status: ChatMessageStatus.complete);
    else if (contentType == MessageType.addGroup)
      message = ChatMessageProvider(status: ChatMessageStatus.complete);
    else if (contentType == MessageType.expelGroup)
      message = ChatMessageProvider(status: ChatMessageStatus.complete);
    else if (contentType == MessageType.text)
      message = ChatMessageProvider(status: ChatMessageStatus.complete);
    else if (contentType == MessageType.urlImg)
      message = ChatMessageProvider(status: ChatMessageStatus.loading);
    else if (contentType == MessageType.urlVoice)
      message = ChatMessageProvider(
          status: ChatMessageStatus.loading,
          readStatus: ChatMessageReadStatus.unRead);
    else {
      if (global.isDebug)
        LogUtil.v("收到消息:${private ? '私' : '群'}[$sourceId]$contentType-暂不支持",
            tag: _tag);
      return;
    }

    if (message == null || !global.profile.isLogged) return;

    var fromFriendId = json["FormId"] as String ?? "";
    if (fromFriendId.isEmpty) return;

    var sendId = json["MessageId"] as String;
    if (sendId == null || sendId.isEmpty) sendId = global.uuid;
    int offset = json["Offset"] as int;

    if (global.isDebug) {
      LogUtil.v(
          "收到消息:${private ? '私' : '群'}[$sourceId]$contentType(offset:$offset)：${DateUtil.formatDate(message.sendTime)}",
          tag: _tag);
      LogUtil.v(jsonStr, tag: _tag);
    }

    if (private && global.profile.offset < offset) {
      global.profile.offset = offset;
      global.profile.serialize();
      offset = 0;
    }

    message
      ..profileId = global.profile.profileId
      ..sourceId = sourceId
      ..sendId = sendId
      ..sendTime = DateTime.fromMillisecondsSinceEpoch(json["SendTime"] as int)
      ..type = contentType
      ..body = json["Body"] as String ?? ""
      ..fromFriendId = fromFriendId
      ..fromNickname = json['NickName'] ?? ""
      ..fromAvatar = json["Avatar"] ?? ""
      ..offset = json["Offset"] as int ?? -1;

    var sourceType = private ? ChatSourceType.contact : ChatSourceType.group;

    if (private) {
      message.sourceId = message.fromFriendId;
      message.toFriendId = global.profile.friendId;
    }

    if (message.type == MessageType.addGroup ||
        message.type == MessageType.expelGroup) {
      message.sourceId = json['GroupID'];
      message.toFriendId = global.profile.friendId;
      sourceType = ChatSourceType.group;
    }

    if (message.type == MessageType.addGroupV2) {
      var text = message.isSelf ? "您邀请了" : "${message.fromNickname}邀请了";
      var list = json['json2'] as Iterable;
      text += list.map((d) {
        return d['FriendId'] == global.profile.friendId ? "您" : d["Remark"];
      }).join("、");
      message.body = text + "加入了群。";
    }

    ChatProvider chat;
    Completer<ChatProvider> completer;
    if (socket._locks.containsKey(message.sourceId)) {
      chat = await socket._locks[message.sourceId];
    }

    var clp = ChatListProvider();
    if (message.type == MessageType.expelGroup) {
      print(message.toJson().toString());
    }
    if (chat == null) {
      chat = clp.getChat(sourceType: sourceType, sourceId: message.sourceId);

      if (chat?.serializeId == null) {
        completer = Completer();
        socket._locks.putIfAbsent(message.sourceId, () => completer.future);

        if (chat == null) {
          chat = await clp.getChatAsync(
              sourceType: sourceType, sourceId: message.sourceId);
        }

        chat.profileId = global.profile.profileId;
        if (message.type == MessageType.addGroup) {
          socket.open(false, chat.sourceId, () => chat.offset);
        }
      }
    }

    if (message.type == MessageType.addGroup) {
      var json2 = json['json2'];
      var groupId = json2['GroupID'];
      var glp = GroupListProvider();
      var group = glp.map[groupId];
      if (group == null) {
        group = GroupProvider()
          ..profileId = global.profile.profileId
          ..groupId = json['GroupID']
          ..name = "群聊"
          ..announcement = ""
          ..createId = "-1"
          ..status = GroupStatus.joined
          ..forbidden = GroupForbiddenStatus.normal
          ..instTime = message.sendTime
          ..updtTime = message.sendTime
          ..serialize(forceUpdate: false);
        glp.groups.add(group);
        glp.forceUpdate();
        group.remoteUpdate(null);
      } else if (group.status != GroupStatus.joined) {
        if (group.createId == null) {
          LogUtil.v("----------------------", tag: _tag);
          LogUtil.v(jsonStr);
          LogUtil.v("----------------------", tag: _tag);
          return;
        }
        group
          ..status = GroupStatus.joined
          ..serialize(forceUpdate: true);
      }

      if (chat.group == null) chat.group = group;
    }

    if (message.type == MessageType.expelGroup) {
      var json2 = json["json2"];
      var groupId = json2['GroupID'];
      socket.close(false, groupId);
      var glp = GroupListProvider();
      var group = glp.map[groupId];
      if (group == null) {
        LogUtil.v("无效退出群群组消息：", tag: _tag);
        LogUtil.v(jsonStr, tag: _tag);
        return;
      }

      /// 更新状态
      if (group.status == GroupStatus.joined) {
        group.status = GroupStatus.exited;
        await group.serialize(forceUpdate: true);
      }
    }

    // TODO:临时过滤掉自己是群主的创建群组消息
//    if (message.type == MessageType.addGroup && chat.latestMsg != null) return;

    // 添加消息是否成功
    // 解决同步消息问题
    // 私聊话题也会收到自己的消息
    // 添加消息没有成功，不做任何处理
    if (!await chat.addMessage(message)) return;

    if (completer == null) {
      clp.sort(forceUpdate: true);
    } else {
      await clp.addChat(chat, sort: true, forceUpdate: true);
      clp.sort(forceUpdate: true);
      completer.complete(chat);
    }

    if (chat.activating) {
      chat.controller.add(message);
    }
    return;
  });
