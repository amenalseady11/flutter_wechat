import 'dart:io';

import 'package:common_utils/common_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_wechat/apis/apis.dart';
import 'package:flutter_wechat/global/global.dart';
import 'package:flutter_wechat/pages/chat/chat.dart';
import 'package:flutter_wechat/pages/chat/widgets/chat_bottom_bar_pane.dart';
import 'package:flutter_wechat/pages/chat/widgets/chat_bottom_bar_pane_emoji.dart';
import 'package:flutter_wechat/pages/chat/widgets/chat_bottom_bar_pane_tool.dart';
import 'package:flutter_wechat/pages/chat/widgets/voice_button.dart';
import 'package:flutter_wechat/providers/chat/chat.dart';
import 'package:flutter_wechat/providers/chat/chat_list.dart';
import 'package:flutter_wechat/providers/chat_message/chat_message.dart';
import 'package:flutter_wechat/providers/contact/contact.dart';
import 'package:flutter_wechat/util/adapter/adapter.dart';
import 'package:flutter_wechat/util/dio/dio.dart';
import 'package:flutter_wechat/util/style/style.dart';
import 'package:flutter_wechat/util/toast/toast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import 'chat_text_field.dart';

class ChatBottomBar extends StatefulWidget {
  @override
  ChatBottomBarState createState() => ChatBottomBarState();
}

class ChatBottomBarState extends State<ChatBottomBar> {
  bool _keyboard = true;
  bool _expand = false;
  bool _expandEmoji = false;

  GlobalKey<ChatTextFieldState> _inputKey = GlobalKey();
  TextEditingController _inputController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    List<Widget> children = [
      _buildLeftIcon(context),
      Expanded(child: _buildCenterChild(context)),
      _buildRightIcon(context),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Style.pBackgroundColor,
        border:
            Border(top: BorderSide(color: Style.pDividerColor, width: ew(1))),
      ),
      constraints: _keyboard ? null : BoxConstraints(maxHeight: ew(108)),
      child: Column(
        children: <Widget>[
          SizedBox(height: ew(10)),
          Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: children),
          SizedBox(height: ew(10)),
          _buildBottomBarPane(context),
        ],
      ),
    );
  }

  Widget _buildLeftIcon(BuildContext context) {
    return IconButton(
      icon: SvgPicture.asset(
        _keyboard
            ? 'assets/images/icons/voice-circle.svg'
            : 'assets/images/icons/keyboard.svg',
        color: Color(0xFF181818),
        width: ew(60),
      ),
      onPressed: () async {
        if (_keyboard && Platform.isAndroid) {
          var permissions = await PermissionHandler().requestPermissions([
            PermissionGroup.speech,
            PermissionGroup.storage,
          ]);
          if (permissions.values.contains(PermissionStatus.denied)) {
            return Toast.showToast(context, message: "请同意授权！");
          }
        }

        _keyboard = !_keyboard;
//        if (!_keyboard)
//          Future.microtask(() {
//            FocusScope.of(context).requestFocus(_inputFocusNode);
//          });
        if (_expand) _expand = false;
        if (_expandEmoji) _expandEmoji = false;
        if (mounted) setState(() {});
      },
    );
  }

  Widget _buildCenterChild(BuildContext context) {
    return Visibility(
      visible: _keyboard,
      child: ChatTextField(
        key: _inputKey,
        controller: _inputController,
        onPressed: () {
          if (_expand && !_expandEmoji) {
            _expand = false;
            if (mounted) setState(() {});
          }
          ChatPageState.of(context, listen: false)
              .toScrollEnd(delay: Future.delayed(Duration(milliseconds: 100)));
        },
      ),
      replacement: ChatVoiceButton(
        startRecord: () {
          if (!_expand) return;
          _expand = false;
          if (mounted) setState(() {});
        },
        stopRecord: _sendVoice,
      ),
    );
  }

  Widget _buildRightIcon(BuildContext context) {
    return Row(
      children: <Widget>[
//        IconButton(
//          icon: SvgPicture.asset(
//              _expandEmoji
//                  ? 'assets/images/icons/keyboard.svg'
//                  : 'assets/images/icons/emoj.svg',
//              color: Style.pTextColor,
//              width: ew(60)),
//          onPressed: () {
//            if (!_keyboard) _keyboard = true;
//            _expandEmoji = !_expandEmoji;
//            _expand = _expandEmoji;
//            if (_expand)
//              ChatPageState.of(context, listen: false).toScrollEnd(
//                  delay: Future.delayed(Duration(milliseconds: 100)));
//            if (mounted) setState(() {});
//          },
//        ),
        Visibility(
          visible: _inputController.text.isEmpty,
          child: Row(children: <Widget>[
            IconButton(
              icon: SvgPicture.asset('assets/images/icons/add.svg',
                  color: Style.pTextColor, width: ew(60)),
              onPressed: () {
                if (!_keyboard) _keyboard = true;
                _expand = !_expand || _expandEmoji;
                _expandEmoji = false;

                if (_expand)
                  ChatPageState.of(context, listen: false).toScrollEnd(
                      delay: Future.delayed(Duration(milliseconds: 100)));
                if (mounted) setState(() {});
              },
            ),
            SizedBox(width: ew(10)),
          ]),
          replacement: Container(
            margin: EdgeInsets.only(right: ew(20)),
            child: RaisedButton(
              elevation: 0,
              highlightElevation: 0,
              child: Text("发送"),
              color: Style.pTintColor,
              textColor: Colors.white,
              onPressed: () => _sendText(context),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBarPane(BuildContext context) {
    var child = _expandEmoji
        ? ChatBottomBarPaneEmoji(onTap: (emoji) {
            this._inputKey.currentState.insertText('":$emoji:"');
          })
        : ChatBottomBarPaneTool(
            onTap: (key) {
              if (key == "gallery")
                return _sendImage(context, source: ImageSource.gallery);

              if (key == "camera")
                return _sendImage(context, source: ImageSource.camera);
            },
          );

    var height = 0.0;
    if (_expand) height = _expandEmoji ? ew(300) : ew(170);

    return ChatBottomBarPane(height: height, child: child);
  }

  Future<ChatMessageProvider> _createSendMsg(
      {@required
          ChatMessageProvider Function(ChatMessageProvider message)
              updated}) async {
    var chat = ChatProvider.of(context, listen: false);
    var message = ChatMessageProvider(
      profileId: global.profile.profileId,
      sendId: global.uuid,
      sendTime: DateTime.now(),
      sourceId: chat.sourceId,
      fromFriendId: global.profile.friendId,
      fromNickname: global.profile.name,
      fromAvatar: global.profile.avatar,
      status: ChatMessageStatus.sending,
    );

    if (chat.isContactChat) {
      message..toFriendId = chat.contact.friendId;
    }

    message = updated(message) ?? message;
    await chat.addMessage(message);
    ChatListProvider.of(context, listen: false).sort(forceUpdate: true);
    return message;
  }

  /// 发送文本消息
  _sendText(BuildContext context) async {
    if (_inputController.text.isEmpty) return;
    var message = await _createSendMsg(updated: (message) {
      return message
        ..type = MessageType.text
        ..body = _inputController.text;
    });
    _expand = false;
    ChatPageState.of(context, listen: false)
        .toScrollEnd(delay: Future.delayed(Duration(milliseconds: 100)));
    _inputController.text = "";
    if (mounted) setState(() {});

    // 发送消息
    var rsp = await toSendMessage(
        private: message.isPrivateMessage,
        sourceId: message.sourceId,
        type: message.type,
        body: message.body);
    await _toSendMsgRsp(rsp);
    if (!rsp.success) {
      message.status = ChatMessageStatus.sendError;
      message.serialize(forceUpdate: true);
      if (mounted) setState(() {});
      return;
    }

    if (rsp.body != null && rsp.body is String && rsp.body.isNotEmpty)
      message.sendId = rsp.body as String;
    message.status = ChatMessageStatus.complete;
    message.serialize(forceUpdate: true);
    if (mounted) setState(() {});
  }

  /// 发送语音
  _sendVoice(String path, double _seconds) async {
    LogUtil.v("语音路径：$path");
    LogUtil.v("语音时长：$_seconds");

    if (_seconds == 0) return;
    var seconds = _seconds.floor();
    if (seconds < 1) return Toast.showToast(context, message: "录音时间太短！");

    var message = await _createSendMsg(updated: (message) {
      return message
        ..type = MessageType.urlVoice
        ..body = path + "?seconds=$seconds"
        ..bodyData = path + "?seconds=$seconds";
    });
    _expand = false;
    ChatPageState.of(context, listen: false)
        .toScrollEnd(delay: Future.delayed(Duration(milliseconds: 100)));
    if (mounted) setState(() {});

    // 上传附件
    var rsp = await toUploadFile(File(path),
        contentType: MediaType("audio", "wav"), suffix: "wav");
    if (!rsp.success) {
      Toast.showToast(context, message: rsp.message);
      message.status = ChatMessageStatus.sendError;
      message.serialize(forceUpdate: true);
      if (mounted) setState(() {});
      return;
    }
    message.body = rsp.body;
    message.serialize(forceUpdate: true);
    if (mounted) setState(() {});

    // 发送消息
    rsp = await toSendMessage(
        private: message.isPrivateMessage,
        sourceId: message.sourceId,
        type: message.type,
        body: message.body);
    await _toSendMsgRsp(rsp);
    if (!rsp.success) {
      message.status = ChatMessageStatus.sendError;
      message.serialize(forceUpdate: true);
      if (mounted) setState(() {});
      return;
    }

    if (rsp.body != null && rsp.body is String && rsp.body.isNotEmpty)
      message.sendId = rsp.body as String;
    message.status = ChatMessageStatus.complete;
    message.serialize(forceUpdate: true);
    if (mounted) setState(() {});
  }

  /// 发送图片
  _sendImage(BuildContext context, {@required ImageSource source}) async {
    File image = await ImagePicker.pickImage(
        source: source ?? ImageSource.gallery,
        maxWidth: 750,
        maxHeight: 1334,
        imageQuality: 100);

    if (image == null) return;

    var message = await _createSendMsg(updated: (message) {
      return message
        ..type = MessageType.urlImg
        ..body = image.path
        ..bodyData = image.path;
    });
    _expand = false;
    ChatPageState.of(context, listen: false)
        .toScrollEnd(delay: Future.delayed(Duration(milliseconds: 100)));
    if (mounted) setState(() {});

    // 上传附件
    var rsp = await toUploadFile(image,
        contentType: MediaType("image", "png"), suffix: "png");
    if (!rsp.success) {
      Toast.showToast(context, message: rsp.message);
      message.status = ChatMessageStatus.sendError;
      message.serialize(forceUpdate: true);
      if (mounted) setState(() {});
      return;
    }
    message.body = rsp.body;
    message.serialize(forceUpdate: true);
    if (mounted) setState(() {});

    // 发送消息
    rsp = await toSendMessage(
        private: message.isPrivateMessage,
        sourceId: message.sourceId,
        type: message.type,
        body: message.body);
    await _toSendMsgRsp(rsp);
    if (!rsp.success) {
      message.status = ChatMessageStatus.sendError;
      message.serialize(forceUpdate: true);
      if (mounted) setState(() {});
      return;
    }

    if (rsp.body != null && rsp.body is String && rsp.body.isNotEmpty)
      message.sendId = rsp.body as String;
    message.status = ChatMessageStatus.complete;
    message.serialize(forceUpdate: true);
    if (mounted) setState(() {});
  }

  _toSendMsgRsp(DioResponse rsp) async {
    if (rsp.success) return;
    var contact = ContactProvider.of(context, listen: false);
    if (contact != null && rsp.message == "您还不是对方的好友") {
      contact.status = ContactStatus.notFriend;
      await contact.serialize(forceUpdate: true);
      return;
    }
    Toast.showToast(context, message: rsp.message);
  }
}
