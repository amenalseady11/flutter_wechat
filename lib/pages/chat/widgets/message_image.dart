import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_wechat/providers/chat_message/chat_message.dart';
import 'package:flutter_wechat/routers/routers.dart';
import 'package:flutter_wechat/util/adapter/adapter.dart';

class MessageImage extends StatelessWidget {
  final ChatMessageProvider message;
  const MessageImage({Key key, this.message}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    // errorWidget: Image.asset("assets/images/chat/image_error.jpg", width: ew(650), height: ew(558),
    return Container(
      margin: message.isSelf
          ? EdgeInsets.only(right: ew(30))
          : EdgeInsets.only(left: ew(30)),
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.3),
          borderRadius: BorderRadius.all(Radius.circular(ew(6)))),
      constraints: BoxConstraints(maxWidth: ew(150)),
      child: GestureDetector(
          child: message.isLocalFile
              ? Image.file(File(message.bodyData))
              : CachedNetworkImage(imageUrl: message.body),
          onTap: () => Routers.navigateTo(
              context,
              Routers.chatGallery +
                  "?sourceId=${message.sourceId}&sendId=${message.sendId}")),
    );
  }
}
