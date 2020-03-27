import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_wechat/global/global.dart';
import 'package:flutter_wechat/pages/mine/qr_code_scan.dart';
import 'package:flutter_wechat/providers/profile/profile.dart';
import 'package:flutter_wechat/routers/routers.dart';
import 'package:flutter_wechat/util/adapter/adapter.dart';
import 'package:flutter_wechat/util/style/style.dart';
import 'package:flutter_wechat/util/toast/toast.dart';
import 'package:flutter_wechat/widgets/action_sheet/action_sheet.dart';
import 'package:flutter_wechat/widgets/avatar/avatar.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QrCodePage extends StatefulWidget {
  @override
  _QrCodePageState createState() => _QrCodePageState();
}

class _QrCodePageState extends State<QrCodePage> {
  var rePainKey = GlobalKey();

  get _qrCodeData {
    return "imchat://${global.pkgName}?type=phone_qrcode&phone=${global.profile.mobile}&salt=${global.profile.salt}";
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Style.pBackgroundColor,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(ew(80)),
        child: AppBar(
          backgroundColor: Style.pBackgroundColor,
          title: Text("二维码名片", style: TextStyle(color: Style.pTextColor)),
          centerTitle: false,
          titleSpacing: -ew(20),
          elevation: 0,
          actions: <Widget>[
            IconButton(
              icon: new SvgPicture.asset(
                'assets/images/contacts/icons_outlined_more.svg',
                color: Style.pTextColor,
              ),
              onPressed: () {
                _showActionSheet(context);
              },
            )
          ],
        ),
      ),
      body: Center(child: _buildBody(context)),
    );
  }

  _buildBody(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: ew(40)),
      padding: EdgeInsets.only(top: ew(30)),
      width: double.maxFinite,
      height: ew(860),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(8.0))),
      child: Column(
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(width: ew(40)),
              Selector<ProfileProvider, String>(
                selector: (context, profile) => profile.avatar ?? "",
                builder: (BuildContext context, String avatar, Widget child) {
                  return CAvatar(avatar: avatar, size: ew(134), radius: ew(8));
                },
              ),
              SizedBox(width: ew(30)),
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SizedBox(height: ew(20)),
                  Container(
                    width: ew(400),
                    child: Selector<ProfileProvider, String>(
                      selector: (context, profile) => profile.name ?? "",
                      builder: (BuildContext context, String nickname,
                          Widget child) {
                        return Text(nickname,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: sp(32)));
                      },
                    ),
                  ),
                  SizedBox(height: ew(10)),
                  Selector<ProfileProvider, String>(
                    selector: (context, profile) => profile.mobile ?? "",
                    builder:
                        (BuildContext context, String mobile, Widget child) {
                      return Text("手机号：" + mobile,
                          style: TextStyle(
                              fontSize: sp(28), color: Style.mTextColor));
                    },
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: ew(10)),
          RepaintBoundary(
            key: rePainKey,
            child: Container(
              color: Colors.white,
              child: QrImage(
                data: _qrCodeData,
                errorCorrectionLevel: QrErrorCorrectLevel.L,
                padding: EdgeInsets.all(ew(40)),
                version: QrVersions.auto,
                size: ew(-40.0 - 30),
//              embeddedImage: NetworkImage(
//                  ProfileProvider.of(context, listen: false).avatar),
              ),
            ),
          )
        ],
      ),
    );
  }

  void _showActionSheet(BuildContext context) async {
    Completer<String> completer = new Completer();
    List<Widget> actions = [];
    actions.add(ActionSheetAction(
      child: Text('保存到手机'),
      onPressed: () {
        Navigator.of(context).pop();
        completer.complete("save_to_phone");
      },
    ));

    actions.add(ActionSheetAction(
      child: Text('扫描二维码'),
      onPressed: () {
        Navigator.of(context).pop();
        completer.complete("scan_qrcode");
      },
    ));

    actions.add(ActionSheetAction(
      child: Text('重置二维码'),
      onPressed: () {
        Navigator.of(context).pop();
        completer.complete("reset_qrcode");
      },
    ));

    ActionSheet.show(
      context,
      actions: actions,
      cancelButton: ActionSheetAction(
        child: Text('取消'),
        onPressed: () {
          Navigator.of(context).pop();
          completer.complete("cancel");
        },
      ),
    );

    var rst = await completer.future;
    if ('cancel' == rst) return;

    if ("scan_qrcode" == rst) {
      if (!await QrCodeScanPage.check(context)) return;
      return Routers.navigateTo(context, Routers.qrCodeScan);
    }

    if ('reset_qrcode' == rst) {
      global.profile.salt++;
      global.profile.serialize();
      if (mounted) setState(() {});
      return;
    }

    if ("save_to_phone" == rst) {
      RenderRepaintBoundary boundary =
          rePainKey.currentContext.findRenderObject();
      var image = await boundary.toImage(pixelRatio: 1.0);
      var byteData = await image.toByteData(format: ImageByteFormat.png);
      var bytes = byteData.buffer.asUint8List();
      var rst = await ImageGallerySaver.saveImage(bytes);
      if (rst == null || rst == false)
        return Toast.showToast(context, message: "保存失败");

      if (rst == true)
        return Toast.showToast(context,
            message: "图片已保存到至相册",
            position: ToastPosition.bottom,
            showTime: 1500);

      var range = rst.split("/");
      rst = range.sublist(3, range.length - 1).join("/");
      Toast.showToast(context,
          message: "图片已保存到至 /$rst/ 文件夹",
          position: ToastPosition.bottom,
          bgColor: Colors.white,
          textColor: Style.sTextColor,
          showTime: 3000);
      return;
    }
  }
}
