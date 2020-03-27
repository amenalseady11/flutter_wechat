import 'package:flutter/material.dart';
import 'package:flutter_wechat/apis/apis.dart';
import 'package:flutter_wechat/global/global.dart';
import 'package:flutter_wechat/providers/contact/contact_list.dart';
import 'package:flutter_wechat/routers/routers.dart';
import 'package:flutter_wechat/util/adapter/adapter.dart';
import 'package:flutter_wechat/util/dialog/dialog.dart';
import 'package:flutter_wechat/util/style/style.dart';
import 'package:flutter_wechat/util/toast/toast.dart';

class AddContactApplyPage extends StatefulWidget {
  final String friendId;

  const AddContactApplyPage({Key key, this.friendId}) : super(key: key);

  @override
  _AddContactApplyPageState createState() => _AddContactApplyPageState();
}

class _AddContactApplyPageState extends State<AddContactApplyPage> {
  _Contact _contact;

  TextEditingController _reason = TextEditingController();
  TextEditingController _remark = TextEditingController();

  @override
  void initState() {
    super.initState();
    var clpm = ContactListProvider.of(context, listen: false).tmpContacts ?? {};
    _contact = _Contact(clpm[widget.friendId] ?? {});

    _reason.text = '我是${global.profile.name}';
    _remark.text = _contact.nickname;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(ew(80)),
        child: AppBar(
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
                  child: Text("发送", style: TextStyle(fontSize: sp(28))),
                  onPressed: () => _send()),
            )
          ],
        ),
      ),
      body: Container(
        padding: EdgeInsets.symmetric(horizontal: ew(60)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <
            Widget>[
          SizedBox(height: ew(120)),
          Container(
            width: double.maxFinite,
            child: Text("申请添加朋友",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: sp(40), color: Style.pTextColor)),
          ),
          SizedBox(height: ew(80)),
          Text("发送添加朋友申请"),
          Container(
            margin: EdgeInsets.only(top: ew(10)),
            padding: EdgeInsets.symmetric(horizontal: ew(30), vertical: ew(10)),
            decoration: BoxDecoration(
                color: Style.pBackgroundColor,
                borderRadius: BorderRadius.all(Radius.circular(ew(6)))),
            child: TextField(
              controller: _reason,
              cursorColor: Style.pTintColor,
              maxLength: 100,
              decoration: InputDecoration(border: InputBorder.none),
              minLines: 3,
              maxLines: 5,
            ),
          ),
          SizedBox(height: ew(80)),
          Text("设置备注"),
          Container(
            margin: EdgeInsets.only(top: ew(10)),
            padding: EdgeInsets.symmetric(horizontal: ew(30), vertical: ew(10)),
            decoration: BoxDecoration(
                color: Style.pBackgroundColor,
                borderRadius: BorderRadius.all(Radius.circular(ew(6)))),
            child: TextField(
              controller: _remark,
              cursorColor: Style.pTintColor,
              maxLength: 20,
              decoration: InputDecoration(border: InputBorder.none),
            ),
          ),
        ]),
      ),
    );
  }

  _send() async {
    if (_remark.text.isEmpty) return alert(context, content: "没有输入备注，请重新填写");
    var rsp = await toAddFriend(
        friendId: _contact.friendId,
        reason: _reason.text,
        remark: _remark.text);
    if (!rsp.success) return Toast.showToast(context, message: rsp.message);
    Toast.showToast(context, message: "发送成功！");
    Routers.navigateTo(context, Routers.home + "?tab=chats",
        clearStack: true, transition: TransitionType.fadeIn);
  }
}

class _Contact {
  final Map<String, dynamic> json;
  _Contact(this.json);

  get applyId => json["ID"] as String ?? "";
  get friendId => json["friendId"] as String ?? "";
  get nickname => json["nickname"] as String ?? "";
}
