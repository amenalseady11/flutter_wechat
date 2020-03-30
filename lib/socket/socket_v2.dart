import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:common_utils/common_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_wechat/apis/apis.dart';
import 'package:flutter_wechat/global/global.dart';
import 'package:flutter_wechat/providers/chat/chat.dart';
import 'package:flutter_wechat/providers/chat/chat_list.dart';
import 'package:flutter_wechat/providers/chat_message/chat_message.dart';
import 'package:flutter_wechat/providers/group/group.dart';
import 'package:flutter_wechat/providers/group/group_list.dart';
import 'package:flutter_wechat/providers/sqflite/sqflite.dart';

const CR = 13;
const LF = 10;

enum SocketStateEnum { normal, creating, connecting, error, stop }

class Socket {
  final String label;
  SocketStateEnum state;
  final HttpClient _client = HttpClient();
  final StreamController<String> _ctl = StreamController();
  Socket._({
    this.state,
    this.label,
  });

  bool get isStop => state == SocketStateEnum.stop;

  Future<HttpClientResponse> connect(String url) async {
    if (isStop) return null;
    HttpClientRequest request = await _client.getUrl(Uri.parse(url));
    // 设置接收字符串
    request.headers.removeAll(HttpHeaders.acceptEncodingHeader);
    // 设置请求的 header
    if (global.profile?.authToken != null)
      request.headers.add("AUTH_TOKEN", global.profile?.authToken);

    HttpClientResponse response = await request.close();

    if (response.statusCode != HttpStatus.ok) return response;

    // 继续读取上次缓冲区域的值
    List<int> bytes = [];
    response.listen((stream) {
      for (int byte in stream) {
        if ((byte == LF || byte == CR)) {
          if (bytes.isEmpty) continue;
          var line = utf8.decode(bytes);
          bytes.clear();
          _ctl.add(line);
          continue;
        }
        bytes.add(byte);
      }
    });
    return response;
  }

  void add(String event) {
    return _ctl.add(event);
  }

  StreamSubscription<String> listen(void onData(String event),
      {Function onError, void onDone(), bool cancelOnError}) {
    return _ctl.stream.listen(onData,
        onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }

  close({bool force: false}) {
    try {
      _ctl.close();
      _client.close(force: true);
    } catch (e) {} finally {
      LogUtil.v("关闭连接($label)", tag: "### Socket ###");
    }
  }
}

class SocketState {
  final bool private;
  final String sourceId;
  final SocketStateEnum state;
  const SocketState(this.private, this.sourceId, this.state);
}

// TODO: 没有办法验证重连机制
class SocketUtil {
  static SocketUtil _instance = SocketUtil._();
  Map<String, Socket> _sockets = {};
  // ignore: close_sinks
  StreamController<SocketState> stateStream = StreamController.broadcast();

  SocketUtil._();

  bool _started = false;

  bool get started => _started;

  SocketUtil start() {
    this.stop();
    this._started = true;
    return this;
  }

  create(
      {@required bool private,
      @required String sourceId,
      @required Function getOffset}) async {
    assert(private != null);
    assert(sourceId != null);
    assert(getOffset != null);

    String socketKey = private ? "/topic/private" : "/topic/group/$sourceId";
    Socket socket = _sockets[socketKey] ??
        Socket._(
          label: "(${private ? '私' : '群'})$socketKey",
          state: SocketStateEnum.normal,
        );

    if (!_sockets.containsKey(socketKey)) {
      _sockets[socketKey] = socket;
    }

    if (socket.state == SocketStateEnum.creating) return;
    if (socket.state == SocketStateEnum.connecting) return;
    socket.state = SocketStateEnum.creating;
    this.stateStream.add(SocketState(private, sourceId, socket.state));

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

    /// TODO: 开发模式调试，获取全部消息
//    if (global.isDevelopment) offset = 0;

    if (global.isDebug)
      LogUtil.v("创建连接:(${private ? '私' : '群'})$socketKey?offset=$offset 开始",
          tag: "### Socket ###");

    var url = "${global.apiBaseUrl}$socketKey?offset=$offset";

    // 创建请求
    HttpClientResponse response = await socket.connect(url);

    if (response?.statusCode != HttpStatus.ok) {
      if (global.isDebug)
        LogUtil.v(
            "创建连接:(${private ? '私' : '群'})$socketKey 失败：${response.statusCode}",
            tag: "### Socket ###");

      socket.state = SocketStateEnum.error;
      this.stateStream.add(SocketState(private, sourceId, socket.state));
      await Future.delayed(Duration(milliseconds: 1000));
      return create(private: private, sourceId: sourceId, getOffset: getOffset);
    }

    if (global.isDebug)
      LogUtil.v("创建连接:(${private ? '私' : '群'})$socketKey:$offset 成功",
          tag: "### Socket ###");

    socket.state = SocketStateEnum.connecting;
    this.stateStream.add(SocketState(private, sourceId, socket.state));

    Map<String, Future<ChatProvider>> locks = {};

    StreamSubscription<String> subscription;
    subscription = socket.listen(
      (jsonStr) async {
        if (socket.state != SocketStateEnum.connecting) {
          socket.state = SocketStateEnum.connecting;
          this.stateStream.add(SocketState(private, sourceId, socket.state));
        }

        if (!global.profile.isLogged || socket.isStop) {
          if (global.isDebug)
            LogUtil.v("取消订阅(${private ? '私' : '群'}[$sourceId])",
                tag: "### Socket ###");
          return subscription?.cancel();
        }

        Map<String, dynamic> json;
        try {
          json = jsonDecode(jsonStr);
        } catch (e) {
          if (global.isDebug) {
            LogUtil.v("解析消息流文本(${private ? '私' : '群'}[$sourceId])异常",
                tag: "### Socket ###");
            LogUtil.v(jsonStr, tag: "### Socket ###");
          }

          LogUtil.e(e, tag: "### Socket ###");
          return;
        }
        String contentType = json["ContentType"];

        if (MessageType.heartbeat == contentType) {
//          if (global.isDebug)
//            LogUtil.v(
//                "收到消息:${private ? '私' : '群'}[$sourceId]心跳包 " +
//                    DateTime.now().toString(),
//                tag: "### Socket ###");
          return;
        }

        if (MessageType.addFriend == contentType ||
            MessageType.addGroup == contentType ||
            MessageType.expelGroup == contentType) {
          // {"MessageId":"64b314b3dded4dcfb7ea9fcc88cdece5","FormId":"-1","NickName":"","Avatar":"","SendTime":1585479059,"Body":"{\"ID\":\"6de44fce1773492dbec882d79d797779\",\"CreatedAt\":\"2020-03-29T10:50:48Z\",\"UpdatedAt\":\"2020-03-29T10:50:59Z\",\"UserID\":\"f72d908583364481ae50f35a9f730486\",\"FriendID\":\"6e6b1cee425e4fc084583a4bbb2768b1\",\"IsBlack\":\"11\",\"IsAgree\":11,\"UtoFRemark\":\"13816881609\",\"FtoURemark\":\"Phone1688\",\"FrUReason\":\"\",\"UrFReason\":\"\"}","Offset":77875,"ContentType":"add-friend/json"}
          var json2;
          try {
            json2 = jsonDecode(json['Body']);
            json["json2"] = json2;
          } catch (e) {
            if (global.isDebug)
              LogUtil.v(
                  "解析 add friend message error(${private ? '私' : '群'}[$sourceId]): $jsonStr",
                  tag: "### Socket ###");
            LogUtil.e(e, tag: "### Socket ###");
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
            json['Body'] = "你已被邀请到群组，可以开始聊天了";
            json["SendTime"] = json["SendTime"] * 1000;
          } else if (MessageType.expelGroup == contentType) {
            json['GroupID'] = json2['GroupID'];
            json['Body'] = "你已被踢出群组";
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
                tag: "### Socket ###");
          return;
        }

        if (message == null || !global.profile.isLogged) return;

        var fromFriendId = json["FormId"] as String ?? "";
        if (fromFriendId.isEmpty) return;

        /// TODO: 暂时过滤掉是自己的发消息，后期处理（需要判断是否已在数据库了）
        if (fromFriendId == global.profile.friendId) return;

        var sendId = json["MessageId"] as String;
        if (sendId == null || sendId.isEmpty) sendId = global.uuid;
        int offset = json["Offset"] as int;

        message
          ..profileId = global.profile.profileId
          ..sourceId = sourceId
          ..sendId = sendId
          ..sendTime =
              DateTime.fromMillisecondsSinceEpoch(json["SendTime"] as int)
          ..type = contentType
          ..body = json["Body"] as String ?? ""
          ..fromFriendId = fromFriendId
          ..fromNickname = json['NickName'] ?? ""
          ..fromAvatar = json["Avatar"] ?? ""
          ..offset = json["Offset"] as int ?? -1;

        var sourceType =
            private ? ChatSourceType.contact : ChatSourceType.group;

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

        ChatProvider chat;
        Completer<ChatProvider> completer;
        if (locks.containsKey(message.sourceId)) {
          chat = await locks[message.sourceId];
        }

        var clp = ChatListProvider();
        if (message.type == MessageType.expelGroup) {
          print(message.toJson().toString());
        }
        if (chat == null) {
          chat =
              clp.getChat(sourceType: sourceType, sourceId: message.sourceId);

          if (chat?.serializeId == null) {
            completer = Completer();
            locks.putIfAbsent(message.sourceId, () => completer.future);

            if (chat == null) {
              chat = await clp.getChatAsync(
                  sourceType: sourceType, sourceId: message.sourceId);
            }

            chat.profileId = global.profile.profileId;
            if (message.type == MessageType.addGroup) {
              create(
                  private: false,
                  sourceId: chat.sourceId,
                  getOffset: () => chat.offset);
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
              LogUtil.v("----------------------", tag: "### Socket ###");
              LogUtil.v(jsonStr);
              LogUtil.v("----------------------", tag: "### Socket ###");
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
          this.remove(private: false, sourceId: groupId);
          var glp = GroupListProvider();
          var group = glp.map[groupId];
          if (group == null) {
            LogUtil.v("无效退出群群组消息：", tag: "### Socket ###");
            LogUtil.v(jsonStr, tag: "### Socket ###");
            return;
          }

          /// 更新状态
          if (group.status == GroupStatus.joined) {
            group.status = GroupStatus.exited;
            await group.serialize(forceUpdate: true);
          }
        }

        await chat.addMessage(message);

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

        if (global.isDebug) {
          debugPrint("");
          LogUtil.v(
              "收到消息:${private ? '私' : '群'}[$sourceId]$contentType(offset:$offset)：${DateUtil.formatDate(message.sendTime)}",
              tag: "### Socket ###");
          LogUtil.v(jsonStr, tag: "### Socket ###");
          debugPrint("");
        }
        return;
      },
      onDone: () {
        if (!_sockets.containsKey(socketKey)) return;
        socket.state = SocketStateEnum.stop;
        this.stateStream.add(SocketState(private, sourceId, socket.state));
        return create(
            private: private, sourceId: sourceId, getOffset: getOffset);
      },
      onError: (error) async {
        if (!_sockets.containsKey(socketKey)) return;
        socket.state = SocketStateEnum.error;
        this.stateStream.add(SocketState(private, sourceId, socket.state));
        int maxCount = 20;
        await Future.doWhile(() async {
          if (!_sockets.containsKey(socketKey)) return false;
          if (maxCount-- <= 0) return false;
          LogUtil.v(
              "等待重连-第${20 - maxCount}次(${private ? '私' : '群'}[$sourceId])",
              tag: "### Sokcet ###");
          if (socket.state == SocketStateEnum.connecting) return false;
          await Future.delayed(Duration(milliseconds: 1500));
          return true;
        });

        if (!_sockets.containsKey(socketKey)) return;
        if (socket.state == SocketStateEnum.connecting) return;
        this.stateStream.add(SocketState(private, sourceId, socket.state));
        return create(
            private: private, sourceId: sourceId, getOffset: getOffset);
      },
      cancelOnError: false,
    );
    return;
  }

  /// 移除某个连接
  remove({@required bool private, @required String sourceId}) {
    // 私聊连接不能移除，私聊是共享连接
    if (private == true) return;
    String socketKey = private ? "/topic/private" : "/topic/group/$sourceId";
    var socket = _sockets.remove(socketKey);
    if (socket == null) return;
    socket.close(force: true);
  }

  /// 停止
  stop() {
    this._started = false;
    _sockets.values.forEach((d) {
      d.state = SocketStateEnum.stop;
      d.close(force: true);
    });
    _sockets.clear();
  }

  SocketState getSocketState({private, String sourceId}) {
    String socketKey = private ? "/topic/private" : "/topic/group/$sourceId";
    if (!_sockets.containsKey(socketKey))
      return SocketState(private, sourceId, SocketStateEnum.normal);
    return SocketState(private, sourceId, _sockets[socketKey].state);
  }
}

SocketUtil socket = SocketUtil._instance;
