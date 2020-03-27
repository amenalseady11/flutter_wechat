import 'package:flutter/material.dart';
import 'package:flutter_wechat/util/adapter/adapter.dart';

class ImageButtonWidget extends StatefulWidget {
  final GestureTapCallback onTap;
  final String image;
  final String highlightImage;

  final double width;
  final double height;

  const ImageButtonWidget(
      {Key key,
      @required this.image,
      this.highlightImage,
      this.onTap,
      this.width,
      this.height})
      : super(key: key);

  @override
  _ImageButtonWidgetState createState() => _ImageButtonWidgetState();
}

class _ImageButtonWidgetState extends State<ImageButtonWidget> {
  bool _highlight = false;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.onTap,
      highlightColor: Colors.transparent,
      splashColor: Colors.transparent,
      focusColor: Colors.transparent,
      child: Image.asset(
        _highlight ? widget.highlightImage : widget.image,
        width: widget.width ?? adapter.ew(36),
        height: widget.width ?? adapter.ew(36),
      ),
      onHighlightChanged: (highlight) {
        setState(() {
          _highlight = highlight;
        });
      },
    );
  }
}
