import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_wechat/util/adapter/adapter.dart';
import 'package:flutter_wechat/util/style/style.dart';
import 'package:flutter_wechat/widgets/mh_text_field/mh_text_field.dart';

///
class GroupSetNamePage extends StatefulWidget {
  final String name;

  const GroupSetNamePage({Key key, this.name}) : super(key: key);

  @override
  _GroupSetNamePageState createState() => _GroupSetNamePageState();
}

class _GroupSetNamePageState extends State<GroupSetNamePage> {
  TextEditingController _name = TextEditingController();

  @override
  void initState() {
    super.initState();
    _name.text = widget.name;
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
          title: Text("设置群聊名称", style: TextStyle(fontSize: sp(32))),
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
                onPressed: _name.text.isNotEmpty && _name.text != widget.name
                    ? () => Navigator.pop(context, _name.text)
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
              child: Text("群聊名称"),
            ),
            Container(
              color: Colors.white,
              margin: EdgeInsets.symmetric(vertical: ew(20)),
              padding:
                  EdgeInsets.symmetric(horizontal: ew(20), vertical: ew(10)),
              child: MHTextField(
                hintText: "新的群聊名称",
                controller: _name,
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
