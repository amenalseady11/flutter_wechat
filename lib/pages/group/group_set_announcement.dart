import 'package:flutter/material.dart';
import 'package:flutter_wechat/util/adapter/adapter.dart';
import 'package:flutter_wechat/util/style/style.dart';

///
class GroupSetAnnouncementPage extends StatefulWidget {
  final String announcement;

  const GroupSetAnnouncementPage({Key key, this.announcement})
      : super(key: key);

  @override
  _GroupSetAnnouncementPageState createState() =>
      _GroupSetAnnouncementPageState();
}

class _GroupSetAnnouncementPageState extends State<GroupSetAnnouncementPage> {
  TextEditingController _name = TextEditingController();

  @override
  void initState() {
    super.initState();
    _name.text = widget.announcement;
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
          title: Text("设置群聊公告", style: TextStyle(fontSize: sp(32))),
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
                onPressed:
                    _name.text.isNotEmpty && _name.text != widget.announcement
                        ? () => Navigator.pop(context, _name.text)
                        : null,
              ),
            )
          ],
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            color: Colors.white,
            margin: EdgeInsets.symmetric(vertical: ew(20)),
            padding: EdgeInsets.symmetric(horizontal: ew(30), vertical: ew(10)),
            child: TextField(
              decoration: InputDecoration(
                border: InputBorder.none,
              ),
              controller: _name,
              maxLength: 100,
              minLines: 6,
              maxLines: 10,
              onChanged: (value) {
                if (mounted) setState(() {});
              },
            ),
          ),
        ],
      ),
    );
  }
}
