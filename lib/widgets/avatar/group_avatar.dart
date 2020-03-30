import 'package:flutter/material.dart';
import 'package:flutter_wechat/util/adapter/adapter.dart';
import 'package:flutter_wechat/util/style/style.dart';
import 'package:cached_network_image/cached_network_image.dart';

var row = 0, column = 0;

// 群聊九宫格头像
class GroupAvatar extends StatelessWidget {
  GroupAvatar({Key key, this.avatars = const [], this.size, this.radius})
      : assert(avatars != null),
        super(key: key);
  final List<String> avatars;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    double size = this.size ?? ew(88);
    double padding = ew(2);
    double margin = ew(2);
    var childCount = avatars.length;
    if (childCount > 9) childCount = 9;
    var columnMax;
    List<Widget> icons = [];
    List<Widget> stacks = [];
    // 五张图片之后（包含5张），每行的最大列数是3
    var imgWidth;

    if (childCount < 2) {
      return Container(width: size, height: size, color: Style.pDividerColor);
    }

    if (childCount >= 5) {
      columnMax = 3;
      imgWidth = (size - (padding * columnMax) - margin) / columnMax;
    } else {
      columnMax = 2;
      imgWidth = (size - (padding * columnMax) - margin) / columnMax;
    }
    for (var i = 0; i < childCount; i++) {
      icons.add(_weChatGroupChatChildIcon(avatars[i], imgWidth));
    }
    row = 0;
    column = 0;
    var centerTop = 0.0;
    if (childCount == 2 || childCount == 5 || childCount == 6) {
      centerTop = imgWidth / 2;
    }
    for (var i = 0; i < childCount; i++) {
      var left = imgWidth * row + padding * (row + 1);
      var top = imgWidth * column + padding * column + centerTop;
      switch (childCount) {
        case 3:
        case 7:
          _topOneIcon(stacks, icons[i], childCount, i, imgWidth, left, top);
          break;
        case 5:
        case 8:
          _topTwoIcon(stacks, icons[i], childCount, i, imgWidth, left, top);
          break;
        default:
          _otherIcon(
              stacks, icons[i], childCount, i, imgWidth, left, top, columnMax);
          break;
      }
    }
    return Container(
      width: size + padding * 2,
      height: size + padding * 2,
      decoration: BoxDecoration(
          color: Style.pDividerColor,
          borderRadius: BorderRadius.all(Radius.circular(radius ?? ew(6)))),
      padding: EdgeInsets.all(padding),
      alignment: AlignmentDirectional.bottomCenter,
      child: Stack(
        children: stacks,
      ),
    );
  }
}

_weChatGroupChatChildIcon(String avatar, double width) {
  if (avatar == null || avatar.isEmpty)
    return Container(
        decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.all(Radius.circular(ew(4)))),
        height: width,
        width: width);
  return Container(
    decoration:
        BoxDecoration(borderRadius: BorderRadius.all(Radius.circular(ew(4)))),
    child: CachedNetworkImage(
      imageUrl: avatar,
      height: width,
      width: width,
      fit: BoxFit.fill,
      placeholder: (context, url) {
        return Container(
            decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.all(Radius.circular(ew(4)))),
            height: width,
            width: width);
      },
    ),
  );
}

// 顶部为一张图片
_topOneIcon(
    List<Widget> stacks, Widget child, int childCount, i, imgWidth, left, top) {
  double margin = ew(2);
  if (i == 0) {
    var firstLeft = imgWidth / 2 + left + margin / 2;
    if (childCount == 7) {
      firstLeft = imgWidth + left + margin;
    }
    stacks.add(Positioned(
      child: child,
      left: firstLeft,
    ));
    row = 0;
    // 换行
    column++;
  } else {
    stacks.add(Positioned(
      child: child,
      left: left,
      top: top,
    ));
    // 换列
    row++;
    if (i == 3) {
      // 第一例
      row = 0;
      // 换行
      column++;
    }
  }
}

// 顶部为两张图片
_topTwoIcon(
    List<Widget> stacks, Widget child, int childCount, i, imgWidth, left, top) {
  double margin = ew(2);
  if (i == 0 || i == 1) {
    stacks.add(Positioned(
      child: child,
      left: imgWidth / 2 + left + margin / 2,
      top: childCount == 5 ? top : 0.0,
    ));
    row++;
    if (i == 1) {
      row = 0;
      // 换行
      column++;
    }
  } else {
    stacks.add(Positioned(
      child: child,
      left: left,
      top: top,
    ));
    // 换列
    row++;
    if (i == 4) {
      // 第一例
      row = 0;
      // 换行
      column++;
    }
  }
}

_otherIcon(List<Widget> stacks, Widget child, int childCount, i, imgWidth, left,
    top, columnMax) {
  stacks.add(Positioned(
    child: child,
    left: left,
    top: top,
  ));
  // 换列
  row++;
  if ((i + 1) % columnMax == 0) {
    // 第一例
    row = 0;
    // 换行
    column++;
  }
}
