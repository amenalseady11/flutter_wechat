import 'package:common_utils/common_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_qr_reader/qrcode_reader_view.dart';
import 'package:flutter_wechat/apis/apis.dart';
import 'package:flutter_wechat/global/global.dart';
import 'package:flutter_wechat/providers/contact/contact_list.dart';
import 'package:flutter_wechat/routers/routers.dart';
import 'package:flutter_wechat/util/toast/toast.dart';
import 'package:permission_handler/permission_handler.dart';

class QrCodeScanPage extends StatefulWidget {
  @override
  _QrCodeScanPageState createState() => _QrCodeScanPageState();

  static check(BuildContext context) async {
    await PermissionHandler().requestPermissions([PermissionGroup.camera]);
    PermissionStatus status =
        await PermissionHandler().checkPermissionStatus(PermissionGroup.camera);
    if (PermissionStatus.denied != status) return true;
    Toast.showToast(context, message: "请同意开启相机权限");
    return false;
  }
}

class _QrCodeScanPageState extends State<QrCodeScanPage> {
  GlobalKey<QrcodeReaderViewState> _key = GlobalKey();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: QrcodeReaderView(
        key: _key,
        onScan: _onScan,
        headerWidget: AppBar(
          iconTheme: IconThemeData(color: Colors.white),
          backgroundColor: Colors.transparent,
          elevation: 0.0,
        ),
      ),
    );
  }

  Future _onScan(String data) async {
    LogUtil.v("扫描结果：${data ?? ""}", tag: "二维码扫描");
    if (data == null || data.isEmpty) return _key.currentState.startScan();

    LogUtil.v("扫描结果：$data", tag: "二维码扫描");

    // 网页
    if (data.startsWith("http://") || data.startsWith("https://")) {
      return Routers.navigateTo(
          context, Routers.webView + "?title=&url=${Uri.encodeComponent(data)}",
          replace: true);
    }

    // 内部app支持的schemes
    if (global.isPkgSchemes(data)) {
      var uri = Uri.tryParse(data);
      if (uri != null) {
        var type = uri.queryParameters['t'];

        // 手机名片
        if (type == "phone_qrcode") {
          var phone = uri.queryParameters['p'];
          if (phone == global.profile.mobile) {
            if (await _toSkipPhonePage(phone)) return;
          }
          _key.currentState.startScan();
          return;
        }
      }
    }

    _key.currentState.startScan();
  }

  _toSkipPhonePage(String phone) async {
    if (phone == null || phone.isEmpty) return false;
    // 无效手机号
    if (!RegexUtil.isMobileSimple(phone)) return false;

//    phone = "13816882001";

    // 扫描到了自己的名片
    if (phone == global.profile.mobile) {
      Routers.navigateTo(context, Routers.homeMime,
          clearStack: true,
          transition: TransitionType.fadeIn,
          transitionDuration: Duration(seconds: 0));
      return true;
    }

    var clp = ContactListProvider.of(context, listen: false);
    // 扫描到了自己的好友
    var concat =
        clp.contacts.firstWhere((d) => d.mobile == phone, orElse: () => null);
    if (concat != null) {
      Routers.navigateTo(
          context, Routers.contact + "?friendId=${concat.friendId}",
          replace: true);
      return true;
    }

    var rsp = await toSearchConcat(phone: phone);
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
        replace: true);
    return true;
  }
}
