import 'package:flutter/material.dart';
import 'package:flutter_wechat/providers/chat/chat_list.dart';
import 'package:flutter_wechat/providers/chat_message/chat_message.dart';
import 'package:flutter_wechat/util/adapter/adapter.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

class ChatGalleryPage extends StatefulWidget {
  final String sourceId;
  final String sendId;

  const ChatGalleryPage({Key key, this.sourceId, this.sendId})
      : super(key: key);

  @override
  _ChatGalleryPageState createState() => _ChatGalleryPageState();
}

class _ChatGalleryPageState extends State<ChatGalleryPage> {
  PageController _page;

  List<ChatMessageProvider> _images;

  @override
  void initState() {
    super.initState();
    var chat = ChatListProvider.of(context, listen: false).map[widget.sourceId];
    _images = chat.messages.where((d) => d.type == MessageType.urlImg).toList();
    var initialPage = 0;
    for (var i = 0; i < _images.length; i++) {
      if (widget.sendId != _images[i].sendId) continue;
      initialPage = i;
      break;
    }
    _page = PageController(initialPage: initialPage);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
          preferredSize: Size.fromHeight(ew(80)),
          child: AppBar(
            backgroundColor: Colors.black,
            brightness: Brightness.dark,
            iconTheme: IconThemeData(color: Colors.white),
          )),
      body: PhotoViewGallery.builder(
        pageController: _page,
        itemCount: _images.length,
        builder: (context, index) {
          var image = _images[index];
          return PhotoViewGalleryPageOptions(
            imageProvider: NetworkImage(image.body),
            initialScale: PhotoViewComputedScale.contained,
            heroAttributes: PhotoViewHeroAttributes(
                tag: image.sendId ?? DateTime.now().toIso8601String()),
          );
        },
      ),
    );
  }
}
