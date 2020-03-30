import 'dart:async';
import 'dart:io';

import 'package:common_utils/common_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_wechat/apis/apis.dart';
import 'package:flutter_wechat/providers/profile/profile.dart';
import 'package:flutter_wechat/util/adapter/adapter.dart';
import 'package:flutter_wechat/util/toast/toast.dart';
import 'package:flutter_wechat/widgets/action_sheet/action_sheet.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_view/photo_view.dart';
import 'package:provider/provider.dart';

class AvatarPage extends StatefulWidget {
  @override
  _AvatarPageState createState() => _AvatarPageState();
}

class _AvatarPageState extends State<AvatarPage> {
  pickImage([ImageSource source = ImageSource.gallery]) async {
    File image = await ImagePicker.pickImage(
        source: source, maxWidth: 800, maxHeight: 800, imageQuality: 90);
    if (image == null) return;

    LogUtil.v("上传头像：" + image.path);

    File croppedFile = await ImageCropper.cropImage(
        maxWidth: 120,
        maxHeight: 120,
        cropStyle: CropStyle.circle,
        sourcePath: image.path,
        aspectRatioPresets: [CropAspectRatioPreset.square],
        androidUiSettings: AndroidUiSettings(
            toolbarTitle: '头像',
            toolbarColor: Colors.black,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            hideBottomControls: true,
            lockAspectRatio: true),
        iosUiSettings: IOSUiSettings(
            rectWidth: 120,
            rectHeight: 120,
            minimumAspectRatio: 1.0,
            title: "头像",
            doneButtonTitle: "确定",
            cancelButtonTitle: "取消"));

    if (croppedFile == null) return;
    LogUtil.v("上传头像：" + croppedFile.path);

    var rsp = await toUploadFile(croppedFile,
        contentType: MediaType("image", "png"), suffix: "png");
    if (!rsp.success) return Toast.showToast(context, message: rsp.message);
    var avatar = rsp.body as String ?? "";
    LogUtil.v("上传头像：" + avatar);

    /// 更新头像地址
    rsp = await toUpdateProfile(avatar: avatar);
    if (!rsp.success) return Toast.showToast(context, message: rsp.message);
    var pp = ProfileProvider.of(context, listen: false);
    await pp.update(avatar: avatar);
    await pp.serialize();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(ew(80)),
        child: AppBar(
          backgroundColor: Colors.black.withOpacity(.9),
          iconTheme: IconThemeData(color: Colors.white),
          title: Text("头像",
              style: TextStyle(color: Colors.white, fontSize: ew(34))),
          centerTitle: false,
          titleSpacing: -ew(20),
          elevation: 0,
          actions: <Widget>[
            IconButton(
              icon: new SvgPicture.asset(
                'assets/images/contacts/icons_outlined_more.svg',
                color: Colors.white,
              ),
              onPressed: () {
                _showActionSheet(context);
              },
            )
          ],
        ),
      ),
      body: Selector<ProfileProvider, String>(
        selector: (context, profile) => profile.avatar ?? "",
        builder: (BuildContext context, String avatar, Widget child) {
          return PhotoView(
            imageProvider: NetworkImage(avatar),
            minScale: 1.0,
            heroAttributes: const PhotoViewHeroAttributes(tag: "avatar"),
          );
        },
      ),
    );
  }

  void _showActionSheet(BuildContext context) async {
    Completer<String> completer = new Completer();

    List<Widget> actions = [];
    actions.add(ActionSheetAction(
      child: Text('从手机相册选择'),
      onPressed: () {
        Navigator.of(context).pop();
        completer.complete("picker_gallery");
      },
    ));

    actions.add(ActionSheetAction(
      child: Text('拍照'),
      onPressed: () {
        Navigator.of(context).pop();
        completer.complete("picker_camera");
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

    if ("picker_gallery" == rst) {
      return pickImage(ImageSource.gallery);
    }

    if ("picker_camera" == rst) {
      return pickImage(ImageSource.camera);
    }
  }
}
