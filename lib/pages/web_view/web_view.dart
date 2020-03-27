import 'package:flutter/material.dart';
import 'package:flutter_wechat/util/adapter/adapter.dart';
import 'package:flutter_wechat/util/dialog/dialog.dart';
import 'package:webview_flutter/webview_flutter.dart';

final key = GlobalKey(debugLabel: "float_button_key");

/// 暂未实现
/// 1. 悬浮按钮，提供返回，退回，切换页面，支持外部链接
/// 2. js桥连接，通信

class WebViewPage extends StatelessWidget {
  final String title;
  final String url;

  const WebViewPage({Key key, @required this.title, @required this.url})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: EdgeInsets.only(
            top: adapter.media.padding.top,
            bottom: adapter.media.padding.bottom),
        child: Stack(
          children: <Widget>[
            _buildWebView(context),
            _buildDraggable(context),
          ],
        ),
      ),
    );
  }

  _buildWebView(BuildContext context) {
    return WebView(
      initialUrl: url,
      javascriptMode: JavascriptMode.unrestricted,
      onPageStarted: (String url) {
        print("webview:$url");
      },
      onPageFinished: (String url) {
        print("webview:$url");
      },
    );
  }

  _buildDraggable(BuildContext context) {
    return DraggableWidget(
      child: FloatingActionButton(
        backgroundColor: Colors.black.withOpacity(0.5),
        key: key,
        child: Icon(Icons.exit_to_app, size: sp(60)),
        elevation: 0,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(adapter.ew(6)))),
        onPressed: () async {
          if (!await confirm(context, content: "确认是否退出？")) return;
          Navigator.pop(context);
        },
      ),
    );
  }
}

class DraggableWidget extends StatefulWidget {
  final Offset offset;
  final Widget child;

  const DraggableWidget({Key key, this.offset, this.child}) : super(key: key);
  @override
  _DraggableWidgetState createState() => _DraggableWidgetState();
}

class _DraggableWidgetState extends State<DraggableWidget> {
  Offset offset;

  @override
  void initState() {
    super.initState();
    offset = widget.offset ?? Offset(ew(-40.0 - 80), ew(40));
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: offset.dx,
      top: offset.dy,
      child: Draggable(
        child: widget.child,
        feedback: widget.child,
        childWhenDragging: Container(),
        onDraggableCanceled: (Velocity velocity, Offset offset) {
          this.offset = offset;
          if (mounted) setState(() {});
        },
      ),
    );
  }
}
