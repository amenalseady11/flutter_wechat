import 'package:flutter/material.dart';
import 'package:flutter_wechat/util/adapter/adapter.dart';
import 'package:flutter_wechat/util/style/style.dart';

class BottomBarToolPane extends StatelessWidget {
  final bool expand;
  final ValueChanged onTap;

  const BottomBarToolPane({Key key, this.expand, this.onTap}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      width: double.maxFinite,
      height: expand ? ew(170) : 0,
      duration: Duration(milliseconds: 100),
      margin: EdgeInsets.symmetric(vertical: ew(10)),
      padding: EdgeInsets.only(top: ew(12), left: ew(20)),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Style.pDividerColor, width: 1),
        ),
      ),
      child: SingleChildScrollView(
        child: Row(children: <Widget>[
          _IconButton(
              icon: Icons.photo,
              title: "相册",
              onPressed: () => onTap('gallery')),
          SizedBox(width: ew(40)),
          _IconButton(
              icon: Icons.photo_camera,
              title: "相机",
              onPressed: () => onTap('camera')),
        ]),
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String title;

  const _IconButton({Key key, this.onPressed, this.icon, this.title})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        RaisedButton(
          color: Colors.white,
          elevation: 0,
          highlightElevation: 0,
          child: Container(
              padding: EdgeInsets.symmetric(vertical: ew(22)),
              child: Icon(icon, size: sp(60))),
          onPressed: onPressed,
        ),
        SizedBox(height: ew(10)),
        Text(title ?? "", style: TextStyle(fontSize: sp(28)))
      ],
    );
  }
}
