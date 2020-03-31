import 'package:common_utils/common_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_wechat/apis/apis.dart';
import 'package:flutter_wechat/providers/home/home.dart';
import 'package:flutter_wechat/providers/profile/profile.dart';
import 'package:flutter_wechat/routers/routers.dart';
import 'package:flutter_wechat/util/adapter/adapter.dart';
import 'package:flutter_wechat/util/dialog/dialog.dart';
import 'package:flutter_wechat/util/style/style.dart';
import 'package:flutter_wechat/util/toast/toast.dart';
import 'package:flutter_wechat/widgets/button/image_button.dart';
import 'package:flutter_wechat/widgets/mh_text_field/mh_text_field.dart';
import 'package:jwt_decode/jwt_decode.dart';

class CaptchaData {
  String text;
  bool disabled = false;

  CaptchaData({this.text, this.disabled = false});
}

class LoginPhonePage extends StatefulWidget {
  @override
  _LoginPhonePageState createState() => _LoginPhonePageState();
}

class _LoginPhonePageState extends State<LoginPhonePage> {
  TextEditingController _zone = TextEditingController(text: "86");
  TextEditingController _phone = TextEditingController();
  TextEditingController _captcha = TextEditingController();
  CaptchaData _captchaData = CaptchaData(text: "获取验证码");

  String _zoneName = "中国大陆";

  bool get disableLogin {
    return _zone.text.isEmpty ||
        _phone.text.length != 11 ||
        _captcha.text.length != 4;
  }

  var _loading = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).requestFocus(FocusNode());
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // 关闭按钮
            Container(
              margin: EdgeInsets.only(
                  top: adapter.media.padding.top + ew(40), left: ew(40)),
              child: ImageButtonWidget(
                image:
                    "assets/images/login/wsactionsheet_close_normal_16x16.png",
                highlightImage:
                    "assets/images/login/wsactionsheet_close_press_16x16.png",
                onTap: () => Navigator.pop(context),
              ),
            ),

            Container(
              margin: EdgeInsets.only(top: ew(150)),
              padding: EdgeInsets.symmetric(horizontal: ew(40)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    "手机登录/注册",
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      color: Colors.black.withOpacity(.9),
                      fontSize: sp(48),
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  SizedBox(height: ew(100)),
                  _buildDivider(),
                  // 地区
                  _buildZoneWidget(context),
                  _buildDivider(),
                  // 手机号
                  _buildPhoneWidget(context),
                  _buildDivider(),
                  // 验证码
                  _buildCaptchaWidget(context),
                  _buildDivider(),
                  _buildLoginButtonWidget(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  _buildZoneWidget(BuildContext context) {
    return InkWell(
      onTap: () {},
      child: Row(
        children: <Widget>[
          SizedBox(
            width: ew(160),
            child: Text(
              '国家/地区',
              style: TextStyle(color: Style.pTextColor, fontSize: sp(32)),
            ),
          ),
          SizedBox(
            width: ew(1.0),
            height: ew(80.0),
//            child: VerticalDivider(
//              width: ew(1.0),
//              color: Style.pDividerColor,
//            ),
          ),
          SizedBox(width: ew(30)),
          Expanded(
            child: InkWell(
              child: Text(
                _zoneName,
                style: TextStyle(color: Style.pTextColor, fontSize: sp(32)),
              ),
              onTap: () {
                Toast.showToast(context, message: "暂未支持国家/地区选择");
              },
            ),
          ),
          Image.asset('assets/images/icons/tableview_arrow_8x13.png',
              width: ew(16), height: ew(26))
        ],
      ),
    );
  }

  _buildPhoneWidget(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: ew(160.0),
          child: MHTextField(
            enabled: false,
            controller: _zone,
            prefixMode: MHTextFieldWidgetMode.always,
            clearButtonMode: MHTextFieldWidgetMode.never,
            maxLength: 4,
            prefix: Text(
              '+',
              style: TextStyle(
                  color: Style.pTextColor,
                  fontSize: sp(34),
                  fontWeight: FontWeight.w500),
            ),
            onChanged: (value) {
              Toast.showToast(context, message: "$value");
            },
          ),
        ),
        SizedBox(
          width: ew(1.0),
          height: ew(80.0),
          child: VerticalDivider(
            width: ew(1.0),
            color: Style.pDividerColor,
          ),
        ),
        SizedBox(width: ew(30)),
        Expanded(
          child: MHTextField(
            controller: _phone,
            prefixMode: MHTextFieldWidgetMode.always,
            clearButtonMode: MHTextFieldWidgetMode.never,
            maxLength: 11,
            hintText: "请输入手机号码",
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [WhitelistingTextInputFormatter.digitsOnly],
            onChanged: (value) {
              // 更新按钮状态
              setState(() {});
            },
          ),
        )
      ],
    );
  }

  _buildCaptchaWidget(BuildContext context) {
    return InkWell(
      onTap: () {},
      child: Row(
        children: <Widget>[
          SizedBox(
            width: ew(160),
            child: Text(
              '验证码',
              style: TextStyle(color: Style.pTextColor, fontSize: sp(32)),
            ),
          ),
          SizedBox(width: ew(1.0), height: ew(80.0)),
          SizedBox(width: ew(30)),
          Expanded(
            child: MHTextField(
              controller: _captcha,
              keyboardType: TextInputType.number,
              hintText: '请输入验证码',
              clearButtonMode: MHTextFieldWidgetMode.never,
              maxLength: 4,
              onChanged: (value) {
                // 更新按钮状态
                setState(() {});
              },
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: ew(10), vertical: ew(4)),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(ew(4))),
              border: Border.all(
                  color: _captchaData.disabled
                      ? Color(0xFF999999)
                      : Color(0xFF353535)),
            ),
            child: InkWell(
              onTap: _captchaData.disabled ? null : () => _sendCaptcha(context),
              child: Text(
                _captchaData.text,
                style: TextStyle(
                  color: _captchaData.disabled
                      ? Color(0xFF999999)
                      : Style.pTextColor,
                  fontSize: sp(26),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建登陆按钮部件
  Widget _buildLoginButtonWidget(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: ew(100)),
      child: Opacity(
        opacity: disableLogin ? 0.5 : 1,
        child: Row(
          children: <Widget>[
            Expanded(
              child: RaisedButton(
                padding: EdgeInsets.symmetric(vertical: ew(22)),
                color: Style.pTintColor,
                highlightColor:
                    disableLogin ? Colors.transparent : Style.sTintColor,
                splashColor: disableLogin ? Colors.transparent : null,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(ew(8))),
                ),
                onPressed: _login,
                child: Text(
                  "登录 / 注册",
                  style: TextStyle(
                    letterSpacing: ew(1),
                    fontSize: sp(34),
                    color: Colors.white,
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  // 构建分割线
  Widget _buildDivider() {
    return Divider(
      height: ew(1),
      color: Style.pDividerColor,
    );
  }

  _sendCaptcha(BuildContext context) async {
    FocusScope.of(context).requestFocus(FocusNode());
    if (_captchaData.disabled) return;
    var phone = _phone.text;
    if (!RegexUtil.isMobileExact(phone))
      return Toast.showToast(context, message: "手机号码不正确");

    var content = "我们将发送验证码短信到这个号码：${_phone.text}";
    if (!await confirm(context, content: content, title: "确认手机号码")) return;
    _captchaData
      ..text = "发送中..."
      ..disabled = true;
    if (mounted) setState(() {});

    var rsp = await toGetVerifySms(mobile: phone);
    if (!rsp.success) {
      _captchaData
        ..text = "获取验证码"
        ..disabled = false;
      if (mounted) setState(() {});
      return Toast.showToast(context, message: rsp.message);
    }

    const max = 60;
    Stream<int>.periodic(Duration(seconds: 1), (num) => max - num)
        .takeWhile((num) => num >= 0)
        .listen((num) {
      if (num == null) return;
      if (!mounted) return;
      setState(() {
        if (num == 0) {
          _captchaData
            ..text = "获取验证码"
            ..disabled = false;
          return;
        }
        _captchaData
          ..text = "$num后重新发送"
          ..disabled = true;
      });
    });
  }

  _login() async {
    FocusScope.of(context).requestFocus(FocusNode());
    if (this.disableLogin) return;
    if (_loading) return;
    _loading = true;
    var rsp =
        await toLoginOrRegister(mobile: _phone.text, captcha: _captcha.text);
    if (!rsp.success) {
      _loading = false;
      return Toast.showToast(context, message: rsp.message);
    }

    var profile = ProfileProvider.of(context, listen: false);
    profile.authToken = rsp.body as String;

    // 解密签名令牌
    Map<String, dynamic> json = Jwt.parseJwt(profile.authToken);

    profile.friendId = json["id"] as String ?? "";
    profile.mobile = json["username"] as String ?? "";

    rsp = await toGetUserBriefly(friendId: profile.friendId);
    if (!rsp.success) {
      _loading = false;
      profile.authToken = null;
      return Toast.showToast(context, message: rsp.message);
    }

    profile.avatar = rsp.body["Avatar"] as String ?? "";
    profile.nickname = rsp.body["NickName"] as String ?? "";

    _loading = false;

    await profile.login();
    HomeProvider.of(context, listen: false).tab = 0;
    Routers.navigateTo(context, Routers.root, clearStack: true);
  }
}
