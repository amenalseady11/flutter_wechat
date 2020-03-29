import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_wechat/apis/apis.dart';
import 'package:flutter_wechat/routers/routers.dart';
import 'package:flutter_wechat/util/adapter/adapter.dart';
import 'package:flutter_wechat/util/style/style.dart';
import 'package:flutter_wechat/util/toast/toast.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class DiscoverPage extends StatefulWidget {
  @override
  _DiscoverPageState createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  var _refreshController = RefreshController(initialRefresh: false);
  List<Map> minis = [];
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
    var rsp = await toGetMinisByPage(pageNo: pageNo, pageSize: pageSize);
    _loading = false;
    rsp.success
        ? _refreshController.refreshCompleted()
        : _refreshController.refreshFailed();
    if (!rsp.success) return Toast.showToast(context, message: rsp.message);
    if (rsp.body == null) return;
    List<Map> list = [];
    if (rsp.body is Map) {
      list.add(rsp.body as Map);
    } else if (rsp.body is Iterable) {
      var list2 = (((rsp.body as Iterable) ?? []) as Iterable<Map>).toList();
      list.addAll(list2);
    }
    minis = list;
    if (mounted) setState(() {});
  }

  toPullUpLoad() async {
    if (_loading) return;
    _loading = true;
    var rsp = await toGetMinisByPage(pageNo: pageNo, pageSize: pageSize);
    _loading = false;
    if (!rsp.success) _refreshController.loadFailed();
    if (!rsp.success) return Toast.showToast(context, message: rsp.message);
    var list = (rsp.body as Iterable) ?? [];
    list.length > 0
        ? _refreshController.loadComplete()
        : _refreshController.loadNoData();
    minis.addAll(list);
  }

  @override
  Widget build(BuildContext context) {
    return SmartRefresher(
      controller: _refreshController,
      enablePullUp: true,
      enablePullDown: true,
      child: _buildChild(context),
      footer: ClassicFooter(
        loadStyle: LoadStyle.ShowWhenLoading,
        completeDuration: Duration(milliseconds: 500),
      ),
      header: WaterDropHeader(waterDropColor: Style.pTintColor),
      onRefresh: () async {
        this.toRefresh();
      },
      onLoading: () async {
        this.toPullUpLoad();
      },
    );
  }

  _buildChild(BuildContext context) {
    return ListView.separated(
      padding: EdgeInsets.only(left: 5, right: 5),
      itemBuilder: (c, i) => _buildMiniWidget(c, minis[i]),
      separatorBuilder: (context, index) {
        return Container(height: ew(1), color: Style.pDividerColor);
      },
      itemCount: minis.length,
    );
  }

  _buildMiniWidget(BuildContext c, Map mini) {
    return Column(
      children: <Widget>[
        ListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(ew(6)),
            child: CachedNetworkImage(
              imageUrl: mini["MiniLogo"] ?? "",
              width: ew(72),
              height: ew(72),
              placeholder: (context, url) {
                return Container(
                    width: ew(72),
                    height: ew(72),
                    color: Colors.grey.withOpacity(0.3));
              },
            ),
          ),
          title: Text(mini["MiniName"] ?? ""),
          subtitle: Text(mini["MiniDesc"] ?? "'"),
          trailing: Image.asset("assets/images/icons/tableview_arrow_8x13.png",
              width: ew(16), height: ew(26)),
          onTap: () {
            var url = mini['MiniAddress'];
            url = Routers.webView +
                "?title=${Uri.encodeComponent(mini['MiniName'])}&url=${Uri.encodeComponent(url)}";
            Routers.navigateTo(context, url);
          },
        ),
      ],
    );
  }
}
