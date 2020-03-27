import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_wechat/apis/apis.dart';
import 'package:flutter_wechat/global/global.dart';
import 'package:flutter_wechat/providers/contact/contact_list.dart';
import 'package:flutter_wechat/routers/routers.dart';
import 'package:flutter_wechat/util/adapter/adapter.dart';
import 'package:flutter_wechat/util/style/style.dart';
import 'package:flutter_wechat/util/toast/toast.dart';
import 'package:flutter_wechat/widgets/mh_text_field/mh_text_field.dart';

class AddContactPage extends StatefulWidget {
  @override
  _AddContactPageState createState() => _AddContactPageState();
}

class _AddContactPageState extends State<AddContactPage> {
  TextEditingController _mobile = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Style.pBackgroundColor,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(ew(80)),
        child: AppBar(
          title: Text('添加朋友'),
          centerTitle: false,
          titleSpacing: -ew(20),
        ),
      ),
      body: Column(
        children: <Widget>[
          SizedBox(height: ew(40)),
          Container(
            color: Colors.white,
            alignment: Alignment.center,
            child: MHTextField(
              controller: _mobile,
              clearButtonMode: MHTextFieldWidgetMode.whileEditing,
              textAlign: TextAlign.center,
              maxLength: 11,
              hintText: "🔍 手机号",
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [WhitelistingTextInputFormatter.digitsOnly],
              onChanged: (value) {
                if (mounted) setState(() {});
              },
            ),
          ),
          Container(child: _mobile.text.length == 0 ? _qrCode() : _phone())
        ],
      ),
    );
  }

  _phone() {
    return InkWell(
      onTap: () => _searchPhone(),
      child: Container(
        padding: EdgeInsets.all(ew(20)),
        color: Colors.white30,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Image.asset("assets/images/icons/add_friend_icon_search@3x.png",
                width: ew(80), height: ew(80)),
            SizedBox(width: ew(30)),
            Text('搜索：',
                style: TextStyle(fontSize: ew(30), color: Style.pTextColor)),
            Text('${_mobile.text}',
                style: TextStyle(fontSize: ew(38), color: Style.pTintColor)),
          ],
        ),
      ),
    );
  }

  _qrCode() {
    return InkWell(
      onTap: () => Routers.navigateTo(context, Routers.qrCode),
      child: Container(
        padding: EdgeInsets.only(top: ew(30), bottom: ew(60)),
        color: Colors.white30,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text("我的手机号：",
                style: TextStyle(fontSize: ew(24), color: Style.sTextColor)),
            Text("${global.profile.mobile}",
                style: TextStyle(fontSize: ew(26), color: Colors.black87)),
            SizedBox(width: ew(20)),
            Image.asset("assets/images/icons/add_friend_myQR_20x20.png",
                width: ew(72 / 2), height: ew(72 / 2))
          ],
        ),
      ),
    );
  }

  _searchPhone() async {
    if (_mobile.text.isEmpty) return;
    if (_mobile.text == global.profile.mobile) {
      return Toast.showToast(context, message: "不能输入自己的手机号");
    }

    var clp = ContactListProvider.of(context, listen: false);
    var contact = clp.contacts
        .firstWhere((d) => d.mobile == _mobile.text, orElse: () => null);
    if (contact != null) {
      var friendId = contact.friendId;
      Routers.navigateTo(context, Routers.contact + "?friendId=$friendId",
          replace: false);
      return;
    }

    var rsp = await toSearchConcat(phone: _mobile.text);
    if (!rsp.success) {
      Toast.showToast(context, message: rsp.message);
      return false;
    }

    var json = rsp.body as Map<String, dynamic>;
    json['friendId'] = json['FriendID'];
    json['mobile'] = json['MobileNumber'];
    json['avatar'] = json['Avatar'];
    json['nickname'] = json['NickName'];
    json['remark'] = json['Remark'];
    json['applyId'] = json['ID'];
    json['black'] = json['IsBlack'];
    json['initial'] = json['Initial'];

    var friendId = json['friendId'];

    if (clp.tmpContacts.containsKey(friendId)) clp.tmpContacts.remove(friendId);
    clp.tmpContacts.putIfAbsent(friendId, () => json);

    Routers.navigateTo(context, Routers.contact + "?friendId=$friendId",
        replace: false);
  }
}
