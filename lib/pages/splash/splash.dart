import 'package:flutter/material.dart';
import 'package:flutter_wechat/util/adapter/adapter.dart';

class SplashPage extends StatefulWidget {
  @override
  _SplashPageState createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // 适配器
    adapter.init(context);
    return Scaffold(
      body: Center(
        child: Text("加载中"),
      ),
    );
  }
}
