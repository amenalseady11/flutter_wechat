import 'package:flutter/material.dart';
import 'package:flutter_wechat/apis/apis.dart';
import 'package:flutter_wechat/providers/contact/contact.dart';
import 'package:flutter_wechat/providers/contact/contact_list.dart';
import 'package:flutter_wechat/util/adapter/adapter.dart';
import 'package:flutter_wechat/util/dialog/dialog.dart';
import 'package:flutter_wechat/util/style/style.dart';
import 'package:flutter_wechat/util/toast/toast.dart';
import 'package:flutter_wechat/widgets/avatar/avatar.dart';

class AddContactApprovePage extends StatefulWidget {
  final String friendId;

  const AddContactApprovePage({Key key, this.friendId}) : super(key: key);

  @override
  _AddContactApprovePageState createState() => _AddContactApprovePageState();
}

class _AddContactApprovePageState extends State<AddContactApprovePage> {
  _AddContactApprove _contact;

  TextEditingController _remark = TextEditingController();

  @override
  void initState() {
    super.initState();
    var clpm = ContactListProvider.of(context, listen: false).tmpContacts ?? {};
    _contact = _AddContactApprove(clpm[widget.friendId] ?? {});
    _remark.text = _contact.nickname;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Style.pBackgroundColor,
      appBar: PreferredSize(
          preferredSize: Size.fromHeight(ew(80)),
          child: AppBar(title: Text("详细资料"))),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildHead(context),
          Container(
            padding: EdgeInsets.symmetric(horizontal: ew(40)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SizedBox(height: ew(60)),
                Text("朋友申请"),
                SizedBox(height: ew(10)),
                Container(
                  width: double.maxFinite,
                  color: Colors.white,
                  padding: EdgeInsets.all(ew(24)),
                  constraints: BoxConstraints(minHeight: ew(200)),
                  child: Text(_contact.reason,
                      style:
                          TextStyle(fontSize: sp(28), color: Colors.black54)),
                ),
                SizedBox(height: ew(80)),
                Text("设置备注"),
                Container(
                  margin: EdgeInsets.only(top: ew(10)),
                  padding: EdgeInsets.symmetric(
                      horizontal: ew(30), vertical: ew(10)),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.all(Radius.circular(ew(6)))),
                  child: TextField(
                    focusNode: FocusNode(),
                    controller: _remark,
                    cursorColor: Style.pTintColor,
                    maxLength: 20,
                    decoration: InputDecoration(border: InputBorder.none),
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(top: ew(60)),
                  height: ew(100),
                  width: double.maxFinite,
                  child: RaisedButton(
                    color: Style.pTintColor,
                    textColor: Colors.white,
                    highlightElevation: 0,
                    elevation: 0,
                    child: Text("通过验证", style: TextStyle(fontSize: sp(30))),
                    onPressed: () => _toApprove(1),
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(top: ew(50)),
                  height: ew(100),
                  width: double.maxFinite,
                  child: RaisedButton(
                    color: Colors.white,
                    highlightElevation: 0,
                    elevation: 0,
//                    textColor: Colors.white,
                    child: Text("拒绝验证",
                        style: TextStyle(
                            fontSize: sp(30), color: Style.sTextColor)),
                    onPressed: () => _toApprove(0),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  _buildHead(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: ew(40), vertical: ew(30)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          CAvatar(
            avatar: _contact.avatar,
            size: ew(120),
            radius: ew(8),
            onTap: () => _viewAvatar(context),
          ),
          SizedBox(width: ew(30)),
          Expanded(
            child: Container(
              height: ew(120),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(_contact.nickname,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: sp(38))),
                    SizedBox(height: ew(12)),
                    Text("手机号：" + _contact.mobile,
                        style: TextStyle(
                            fontSize: sp(28), color: Style.mTextColor))
                  ]),
            ),
          )
        ],
      ),
    );
  }

  _viewAvatar(BuildContext context) {}

  _toApprove(int state) async {
    if (_remark.text.isEmpty) return alert(context, content: "没有输入备注，请重新填写");

    var rsp = await toApproveAddContactApply(
        applyId: _contact.applyId,
        friendId: _contact.friendId,
        state: state,
        remark: _remark.text);
    if (!rsp.success) return Toast.showToast(context, message: rsp.message);
    var clp = ContactListProvider.of(context, listen: false);
    var contact = ContactProvider.fromJson(_contact.json);
    clp.addContact(contact);
    Navigator.pop(context, true);
  }
}

class _AddContactApprove {
  final Map<String, dynamic> json;
  _AddContactApprove(this.json);

  get applyId => json['applyId'] as String ?? "";
  get friendId => json['friendId'] as String ?? "";
  get nickname => json["nickname"] as String ?? "";
  get mobile => json["mobile"] as String ?? "";
  get avatar => json["avatar"] as String ?? "";
  get reason => json["reason"] as String ?? "";
}
