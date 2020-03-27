import 'package:flutter/material.dart';
import 'package:flutter_wechat/apis/apis.dart';
import 'package:flutter_wechat/global/global.dart';
import 'package:flutter_wechat/providers/profile/profile.dart';
import 'package:flutter_wechat/util/adapter/adapter.dart';
import 'package:flutter_wechat/util/dialog/dialog.dart';
import 'package:flutter_wechat/util/style/style.dart';
import 'package:flutter_wechat/util/toast/toast.dart';
import 'package:flutter_wechat/widgets/mh_text_field/mh_text_field.dart';

class SetNicknamePage extends StatefulWidget {
  @override
  _SetNicknamePageState createState() => _SetNicknamePageState();
}

class _SetNicknamePageState extends State<SetNicknamePage> {
  TextEditingController _nickname = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nickname.text = global.profile.nickname;
  }

  get disabled => _nickname.text == global.profile.nickname;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(ew(80)),
        child: AppBar(
          elevation: 0,
          titleSpacing: -ew(20),
          title: Text("更改昵称",
              style: TextStyle(
                  fontSize: sp(34),
                  color: Style.pTextColor,
                  fontWeight: FontWeight.w400)),
          centerTitle: false,
          backgroundColor: Colors.white,
          actions: <Widget>[
            Container(
              margin: EdgeInsets.only(right: ew(20)),
              padding: EdgeInsets.symmetric(vertical: ew(10)),
              child: RaisedButton(
                color: Style.pTintColor,
                textColor: Colors.white,
                disabledColor: Colors.grey.withOpacity(0.7),
                disabledTextColor: Colors.white,
                elevation: 0,
                clipBehavior: Clip.hardEdge,
                child: Text("保存", style: TextStyle(fontSize: sp(28))),
                onPressed: disabled
                    ? null
                    : () {
                        _save(context);
                      },
              ),
            )
          ],
        ),
      ),
      body: Container(
        padding: EdgeInsets.symmetric(horizontal: ew(10)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(height: ew(50)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: ew(20)),
              child: MHTextField(
                focusNode: FocusNode(),
                controller: _nickname,
                clearButtonMode: MHTextFieldWidgetMode.whileEditing,
                maxLength: 30,
                onChanged: (value) {
                  if (mounted) setState(() {});
                },
              ),
            ),
            Divider(height: ew(1), color: Style.pTintColor),
            SizedBox(height: ew(20)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: ew(10)),
              child: Text("好名字可以让你的朋友更容易记住你。",
                  style: TextStyle(fontSize: sp(26), color: Style.mTextColor)),
            )
          ],
        ),
      ),
    );
  }

  void _save(BuildContext context) async {
    if (_nickname.text.isEmpty) return alert(context, content: "没有输入昵称，请重新填写");
    var rsp = await toUpdateProfile(nickname: _nickname.text);
    if (!rsp.success) return Toast.showToast(context, message: rsp.message);
    var pp = ProfileProvider.of(context, listen: false);
    pp.update(nickname: _nickname.text);
    await pp.serialize();
    Navigator.pop(context);
  }
}
