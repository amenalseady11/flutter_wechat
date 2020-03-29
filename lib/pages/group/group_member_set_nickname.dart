import 'package:flutter/material.dart';
import 'package:flutter_wechat/util/adapter/adapter.dart';
import 'package:flutter_wechat/util/style/style.dart';
import 'package:flutter_wechat/widgets/mh_text_field/mh_text_field.dart';

///
class GroupMemberSetNicknamePage extends StatefulWidget {
  final String nickname;

  const GroupMemberSetNicknamePage({Key key, this.nickname}) : super(key: key);

  @override
  _GroupMemberSetNicknamePageState createState() =>
      _GroupMemberSetNicknamePageState();
}

class _GroupMemberSetNicknamePageState
    extends State<GroupMemberSetNicknamePage> {
  TextEditingController _nickname = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nickname.text = widget.nickname;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Style.pBackgroundColor,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(ew(80)),
        child: AppBar(
          backgroundColor: Style.pBackgroundColor,
          elevation: 0.0,
          title: Text("设置群昵称", style: TextStyle(fontSize: sp(32))),
          titleSpacing: -ew(20),
          centerTitle: false,
          actions: <Widget>[
            Container(
              padding: EdgeInsets.symmetric(vertical: ew(10)),
              margin: EdgeInsets.only(right: ew(20)),
              child: RaisedButton(
                color: Style.pTintColor,
                textColor: Colors.white,
                disabledTextColor: Colors.white60,
                disabledColor: Colors.grey.withOpacity(0.6),
                elevation: 0.0,
                child: Text('确定'),
                onPressed: _nickname.text.isNotEmpty &&
                        _nickname.text != widget.nickname
                    ? () => Navigator.pop(context, _nickname.text)
                    : null,
              ),
            )
          ],
        ),
      ),
      body: Padding(
        padding: EdgeInsets.only(top: ew(40)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: EdgeInsets.only(left: ew(20)),
              child: Text("群昵称"),
            ),
            Container(
              color: Colors.white,
              margin: EdgeInsets.symmetric(vertical: ew(20)),
              padding:
                  EdgeInsets.symmetric(horizontal: ew(20), vertical: ew(10)),
              child: MHTextField(
                hintText: "新的群昵称",
                controller: _nickname,
                clearButtonMode: MHTextFieldWidgetMode.whileEditing,
                onChanged: (value) {
                  if (mounted) setState(() {});
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
