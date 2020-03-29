import 'package:azlistview/azlistview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_wechat/providers/contact/contact.dart';
import 'package:flutter_wechat/providers/contact/contact_list.dart';
import 'package:flutter_wechat/routers/routers.dart';
import 'package:flutter_wechat/util/adapter/adapter.dart';
import 'package:flutter_wechat/util/style/style.dart';
import 'package:flutter_wechat/widgets/avatar/avatar.dart';
import 'package:flutter_wechat/widgets/popup_menu/popup_menu.dart';
import 'package:provider/provider.dart';

class _AzListViewHeaderItem {
  final String title;
  final String icon;
  final String key;
  const _AzListViewHeaderItem({this.title, this.icon, this.key});
}

final _azListViewHeaderItems = [
  _AzListViewHeaderItem(
      key: "new_friends",
      title: "新的朋友",
      icon: "assets/images/contacts/plugins_FriendNotify_36x36.png"),
  _AzListViewHeaderItem(
      key: "groups",
      title: "群聊",
      icon: "assets/images/contacts/add_friend_icon_addgroup_36x36.png"),
];

class ContactsPage extends StatefulWidget {
  @override
  _ContactsPageState createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  final int _suspensionHeight = 40;

  double _itemHeight = ew(110.0);

  String _suspensionTag = "";

  @override
  void initState() {
    super.initState();
    ContactListProvider.of(context, listen: false).remoteUpdate(context);

//    Future.microtask(() async {
//      var rsp = await getUserBriefly(friendId: Profile().profileId);
//      print('rsp');
//    });
  }

  @override
  Widget build(BuildContext context) {
    print("ContactsPage");
    return Consumer<ContactListProvider>(
        builder: (BuildContext context, clp, Widget child) {
      return Container(
        width: double.maxFinite,
        height: double.maxFinite,
        child: AzListView(
          header: _buildAzListViewHeader(context),
          data: clp.contacts,
          itemBuilder: (context, model) {
            return ContactItemWidget(
              contact: model,
              susWidget: _buildSusWidget(model.getSuspensionTag()),
              itemHeight: _itemHeight,
            );
          },
          suspensionWidget: _buildSusWidget(_suspensionTag),
          isUseRealIndex: false,
          itemHeight: _itemHeight.toInt(),
          suspensionHeight: _suspensionHeight,
          onSusTagChanged: (tag) {
            setState(() {
              _suspensionTag = tag;
            });
          },
        ),
      );
    });
  }

  Widget _buildSusWidget(String susTag) {
    return Container(
      height: _suspensionHeight.toDouble(),
      padding: EdgeInsets.only(left: ew(30)),
      color: Color(0xfff3f4f5),
      alignment: Alignment.centerLeft,
      child: Text(
        '$susTag',
        softWrap: false,
        style: TextStyle(fontSize: sp(28), color: Colors.black87),
      ),
    );
  }

  _buildAzListViewHeader(BuildContext context) {
    return AzListViewHeader(
        tag: "",
        height: (_itemHeight * _azListViewHeaderItems.length + ew(6)).toInt(),
        builder: (context) {
          return Column(
              children: _azListViewHeaderItems
                  .map((d) => _buildAzAzListViewHeaderWidget(d))
                  .toList());
        });
  }

  Widget _buildAzAzListViewHeaderWidget(_AzListViewHeaderItem item) {
    return Column(children: <Widget>[
      Container(
        height: _itemHeight.toDouble(),
        child: ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(ew(6)),
              child: Image.asset(
                item.icon,
                width: ew(72),
                height: ew(72),
                fit: BoxFit.cover,
              ),
            ),
            title: Text(item.title ?? ""),
            onTap: () => _onTap2(item.key)),
      ),
      Divider(
          height: ew(1),
          indent: ew(120),
          endIndent: ew(60),
          color: Style.pDividerColor)
    ]);
  }

  void _onTap2(String key) {
    if ("new_friends" == key) {
      return Routers.navigateTo(context, Routers.addContactApplies);
    }

    if ("groups" == key) {
      return Routers.navigateTo(context, Routers.groups);
    }
//    Toast.showToast(context, message: "点击$key");
  }
}

class ContactItemWidget extends StatefulWidget {
  final ContactProvider contact;
  final Widget susWidget;
  final double itemHeight;

  const ContactItemWidget(
      {Key key, this.contact, this.susWidget, this.itemHeight})
      : super(key: key);
  @override
  _ContactItemWidgetState createState() => _ContactItemWidgetState();
}

class _ContactItemWidgetState extends State<ContactItemWidget> {
  ContactProvider get contact => widget.contact;
  @override
  Widget build(BuildContext context) {
    Offset offset;
    return Column(
      children: <Widget>[
        Offstage(
          offstage: contact.isShowSuspension != true,
          child: widget.susWidget,
        ),
        Container(
          height: widget.itemHeight,
          child: GestureDetector(
              child: ListTile(
                leading: CAvatar(
                    avatar: contact.avatar, size: ew(80), radius: ew(8)),
                title: Text(contact.name),
//                subtitle: Text("手机号：" +
//                    (contact.mobile.length >= 11
//                        ? TextUtil.hideNumber(contact.mobile)
//                        : contact.mobile)),
                onTap: () {
                  Routers.navigateTo(context,
                      Routers.contact + "?friendId=${contact.friendId}");
                },
                onLongPress: () {
                  if (offset == null) return;
                  _showMenu(context, offset);
                },
              ),
              onTapDown: (details) {
                offset = details.globalPosition;
              }),
        ),
        Divider(
            height: ew(1),
            indent: ew(120),
            endIndent: ew(60),
            color: Style.pDividerColor)
      ],
    );
  }

  void _showMenu(BuildContext context, Offset offset) async {
    final RenderBox overlay = Overlay.of(context).context.findRenderObject();
    final RelativeRect position = RelativeRect.fromLTRB(offset.dx, offset.dy,
        overlay.size.width - offset.dx, overlay.size.height - offset.dy);

    var str = await showMenu<String>(
      context: context,
      position: position,
      items: <MyPopupMenuItem<String>>[
        new MyPopupMenuItem(
            child: Text('设置备注与签名', style: TextStyle(fontSize: sp(28))),
            value: 'set_remark'),
      ],
    );

    if ("set_remark" == str) {
      Routers.navigateTo(
          context,
          Routers.contactSetRemark +
              "?friendId=${contact.friendId}&remark=${Uri.encodeFull(contact.name)}");
    }
  }
}
