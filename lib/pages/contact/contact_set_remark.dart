import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_wechat/util/adapter/adapter.dart';
import 'package:flutter_wechat/util/dialog/dialog.dart';
import 'package:flutter_wechat/util/style/style.dart';
import 'package:flutter_wechat/widgets/mh_text_field/mh_text_field.dart';

///
class ContactSetRemark extends StatefulWidget {
  final String remark;
  final String friendId;

  const ContactSetRemark({Key key, this.remark, this.friendId})
      : super(key: key);

  @override
  _ContactSetRemarkState createState() => _ContactSetRemarkState();
}

class _ContactSetRemarkState extends State<ContactSetRemark> {
  TextEditingController _remark = TextEditingController();

  @override
  void initState() {
    super.initState();
    _remark.text = widget.remark;
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
          title: Text("设置备注", style: TextStyle(fontSize: sp(32))),
          titleSpacing: -ew(20),
          centerTitle: false,
          actions: <Widget>[
            FlatButton(
              child: Text(
                "保存",
                style: TextStyle(fontSize: sp(32), fontWeight: FontWeight.w400),
              ),
              onPressed: () {
                _save();
              },
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
              child: Text("备注名"),
            ),
            Container(
              color: Colors.white,
              margin: EdgeInsets.symmetric(vertical: ew(20)),
              padding:
                  EdgeInsets.symmetric(horizontal: ew(20), vertical: ew(10)),
              child: MHTextField(
                hintText: "新的备注名称",
                controller: _remark,
                clearButtonMode: MHTextFieldWidgetMode.whileEditing,
                onChanged: (value) {},
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _save() async {
    await alert(context, content: "${_remark.text} 暂未实现", title: "新的备注名称");
    Navigator.pop(context);
  }
}
