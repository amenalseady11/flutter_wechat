import 'package:flutter/material.dart';
import 'package:flutter_wechat/util/adapter/adapter.dart';
import 'package:flutter_wechat/util/style/style.dart';

class AboutPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(ew(80)),
        child: AppBar(
            elevation: 0,
            titleSpacing: 0,
            title: Text("关于"),
            centerTitle: false,
            backgroundColor: Style.pBackgroundColor),
      ),
    );
  }
}
