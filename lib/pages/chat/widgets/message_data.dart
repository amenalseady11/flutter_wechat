import 'dart:math';

import 'package:flutter_wechat/global/global.dart';
import 'package:flutter_wechat/providers/chat_message/chat_message.dart';

getMessages(String sourceId, int length) {
  var msgs = [];
  msgs.add(ChatMessageProvider(
      fromAvatar: global.profile.avatar,
      fromFriendId: global.profile.friendId,
      type: MessageType.text,
      sourceId: sourceId,
      sendId: global.uuid,
      sendTime: DateTime.now(),
      body:
          "随意祝发财随意祝发财随意祝发财随意祝发财随意祝发财,随意祝发财随意祝发财随意祝发财随意祝发财随意祝发财,随意祝发财随意祝发财随意祝发财随意祝发财随意祝发财,"));

  msgs.add(ChatMessageProvider(
      fromAvatar: global.profile.avatar,
      fromFriendId: global.profile.friendId.substring(1),
      type: MessageType.text,
      sourceId: sourceId,
      sendId: global.uuid,
      sendTime: DateTime.now(),
      body: "随意祝发财"));

  msgs.add(ChatMessageProvider(
      fromAvatar: global.profile.avatar,
      fromFriendId: global.profile.friendId,
      type: MessageType.urlImg,
      sourceId: sourceId,
      sendId: global.uuid,
      sendTime: DateTime.now(),
      body:
          "https://timgsa.baidu.com/timg?image&quality=80&size=b9999_10000&sec=1585027526630&di=1394f16d281c3e916a46a9c01b334df1&imgtype=0&src=http%3A%2F%2Fb.hiphotos.baidu.com%2Fexp%2Fw%3D500%2Fsign%3D0892ad0f283fb80e0cd161d706d12ffb%2F574e9258d109b3de95f94556c5bf6c81800a4c4d.jpg"));

  msgs.add(ChatMessageProvider(
      fromAvatar: global.profile.avatar,
      fromFriendId: global.profile.friendId.substring(1),
      type: MessageType.urlImg,
      sourceId: sourceId,
      sendId: global.uuid,
      sendTime: DateTime.now(),
      body:
          "https://timgsa.baidu.com/timg?image&quality=80&size=b9999_10000&sec=1585027526630&di=1394f16d281c3e916a46a9c01b334df1&imgtype=0&src=http%3A%2F%2Fb.hiphotos.baidu.com%2Fexp%2Fw%3D500%2Fsign%3D0892ad0f283fb80e0cd161d706d12ffb%2F574e9258d109b3de95f94556c5bf6c81800a4c4d.jpg"));

  msgs.add(ChatMessageProvider(
      fromAvatar: global.profile.avatar,
      fromFriendId: global.profile.friendId.substring(1),
      type: MessageType.urlImg,
      sourceId: sourceId,
      sendId: global.uuid,
      sendTime: DateTime.now(),
      body: "https://pcdn.flutterchina.club/imgs/book.png"));

  msgs.add(ChatMessageProvider(
      fromAvatar: global.profile.avatar,
      fromFriendId: global.profile.friendId.substring(1),
      type: MessageType.urlImg,
      sourceId: sourceId,
      sendId: global.uuid,
      sendTime: DateTime.now(),
      body: "https://pcdn.flutterchina.club/imgs/book.png"));

  msgs.add(ChatMessageProvider(
      fromAvatar: global.profile.avatar,
      fromFriendId: global.profile.friendId,
      type: MessageType.urlVoice,
      sourceId: sourceId,
      sendId: global.uuid,
      sendTime: DateTime.now(),
      body:
          "http://148.70.231.222:6543/20200324/c/0/d/5/cd05d95dbe2c4f68844045510e717e35.wav?seconds=13"));

  msgs.add(ChatMessageProvider(
      fromAvatar: global.profile.avatar,
      fromFriendId: global.profile.friendId.substring(1),
      type: MessageType.urlVoice,
      sourceId: sourceId,
      sendId: global.uuid,
      sendTime: DateTime.now(),
      body:
          "http://148.70.231.222:6543/20200324/7/b/9/8/75b29b81134f4ac3b72c3fbfd24f37ae.wav?seconds=90"));

  return List<ChatMessageProvider>.generate(length, (index) {
    ChatMessageProvider message = msgs[Random().nextInt(msgs.length)];
    return ChatMessageProvider.fromJson(message.toJson())..sendId = global.uuid;
  });
}
