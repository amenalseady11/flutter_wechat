import 'package:flutter/material.dart';
import 'package:flutter_wechat/routers/routers.dart';
import 'package:flutter_wechat/socket/socket.dart';
import 'package:flutter_wechat/util/adapter/adapter.dart';

class LoginPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    socket.stop();
    return Scaffold(
      body: Stack(
        alignment: AlignmentDirectional.bottomCenter,
        children: <Widget>[
          Container(
            width: double.maxFinite,
            height: double.maxFinite,
            decoration: BoxDecoration(
              color: Colors.white,
              image: DecorationImage(
                image: AssetImage('assets/images/login/login_bg.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned(
            bottom: adapter.ew(200.0),
            child: RaisedButton(
              padding: EdgeInsets.symmetric(
                  vertical: adapter.ew(18.0), horizontal: adapter.ew(120)),
              color: Color(0xFF07C160),
              highlightColor: Color(0xFF06AD56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(adapter.ew(6))),
              ),
              onPressed: () => _toLoginOrRegister(context),
              textColor: Colors.white,
              child: Text(
                "登录 / 注册",
                style:
                    TextStyle(letterSpacing: 2.0, fontSize: adapter.sp(32.0)),
              ),
            ),
          )
        ],
      ),
    );
  }

  _toLoginOrRegister(BuildContext context) {
//    confirm(context, content: "null");
    Routers.navigateTo(context, Routers.loginPhone);
  }
}
