import 'package:flutter/material.dart';
import 'package:flutter_wechat/apis/apis.dart';
import 'package:flutter_wechat/providers/contact/contact_list.dart';
import 'package:flutter_wechat/routers/routers.dart';
import 'package:flutter_wechat/util/adapter/adapter.dart';
import 'package:flutter_wechat/util/dialog/dialog.dart';
import 'package:flutter_wechat/util/style/style.dart';
import 'package:flutter_wechat/widgets/avatar/avatar.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class AddContactAppliesPage extends StatefulWidget {
  @override
  _AddContactAppliesPageState createState() => _AddContactAppliesPageState();
}

class _AddContactAppliesPageState extends State<AddContactAppliesPage> {
  var _refreshController = RefreshController(initialRefresh: false);
  List<_AddContactApply> _applies = [];
  int pageNo = 1;
  int pageSize = 50;
  var _loading = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      this.toRefresh();
    });
  }

  toRefresh() async {
    if (_loading) return;
    _loading = true;
    var rsp = await toGetAddFriendApplies(pageNo: pageNo, pageSize: pageSize);
    _loading = false;
    rsp.success
        ? _refreshController.refreshCompleted()
        : _refreshController.refreshFailed();
    if (!rsp.success) return alert(context, content: rsp.message);
    _applies.clear();
    if (rsp.body == null) return;
    if (rsp.body is Map) {
    } else if (rsp.body is Iterable) {
      (((rsp.body as Iterable) ?? [])).forEach((json) {
        _applies.add(_AddContactApply(json));
//        var nextInt = Random().nextInt(100);
//        applies.addAll(List.generate(nextInt, (_) => applies[0]));
      });
    }
    if (mounted) setState(() {});
  }

  toPullUpLoad() async {
    if (_loading) return;
    _loading = true;
    var rsp = await toGetMinisByPage(pageNo: pageNo, pageSize: pageSize);
    _loading = false;
    if (!rsp.success) _refreshController.loadFailed();
    if (!rsp.success) return alert(context, content: rsp.message);
    var list = (rsp.body as Iterable) ?? [];
    list.length > 0
        ? _refreshController.loadComplete()
        : _refreshController.loadNoData();
    _applies = list.map((json) => _AddContactApply(json)).toList();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
          preferredSize: Size.fromHeight(ew(80)),
          child: AppBar(
            titleSpacing: -ew(20),
            title: Text("新的朋友"),
            centerTitle: false,
            actions: <Widget>[
              FlatButton(
                child: Text("添加朋友",
                    style:
                        TextStyle(fontSize: sp(30), color: Style.pTextColor)),
                onPressed: () =>
                    Routers.navigateTo(context, Routers.addContact),
              )
            ],
          )),
      body: SmartRefresher(
        controller: _refreshController,
        enablePullUp: false,
        enablePullDown: true,
        child: _buildChild(context),
        footer: ClassicFooter(
          loadStyle: LoadStyle.ShowWhenLoading,
          completeDuration: Duration(milliseconds: 500),
        ),
        header: WaterDropHeader(waterDropColor: Style.pTintColor),
        onRefresh: () => this.toRefresh(),
        onLoading: () => this.toPullUpLoad(),
      ),
    );
  }

  _buildChild(BuildContext context) {
    return ListView.separated(
      itemBuilder: (c, i) => _buildMiniWidget(c, _applies[i]),
      separatorBuilder: (context, index) {
        return Container(height: ew(1), color: Style.pDividerColor);
      },
      itemCount: _applies.length,
    );
  }

  _buildMiniWidget(BuildContext c, _AddContactApply item) {
    return Container(
      child: ListTile(
        leading: CAvatar(avatar: item.avatar, size: ew(90), radius: ew(8)),
        title: Text(item.nickname),
        subtitle: Text("手机号：" + item.mobile),
        trailing: Container(
          width: ew(120),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              Text("23:59"),
              SizedBox(width: ew(10)),
              Image.asset("assets/images/icons/tableview_arrow_8x13.png",
                  width: ew(16), height: ew(26))
            ],
          ),
        ),
        onTap: () => _onTap(item),
      ),
    );
  }

  _onTap(_AddContactApply item) async {
    var clp = ContactListProvider.of(context, listen: false);
    // 是否已是联系人好友
    if (clp.map.containsKey(item.friendId)) {
      var friendId = item.friendId;
      return Routers.navigateTo(
          context, Routers.contact + "?friendId=$friendId");
    }

    var json = item.json;
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
    var rst = await Routers.navigateTo(
        context, Routers.addContactApprove + "?friendId=$friendId");
    if (rst == true) _applies.remove(item);
  }
}

class _AddContactApply {
  final Map<String, dynamic> json;
  _AddContactApply(this.json);

  get applyId => json["ID"] as String ?? "";
  get friendId => json["FriendID"] as String ?? "";
  get nickname => json["NickName"] as String ?? "";
  get mobile => json["MobileNumber"] as String ?? "";
  get avatar => json["Avatar"] as String ?? "";
}
