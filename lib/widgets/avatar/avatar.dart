import 'package:flutter/material.dart';
import 'package:flutter_wechat/util/adapter/adapter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_wechat/util/style/style.dart';

/// 联系人头像
class CAvatar extends StatelessWidget {
  final String avatar;
  final double size;
  final double radius;
  final GestureTapCallback onTap;
  final String heroTag;
  final Color color;

  CAvatar._(
      {Key key,
      @required this.avatar,
      this.size,
      this.radius,
      this.onTap,
      this.heroTag,
      this.color})
      : super(key: key);

  factory CAvatar(
      {Key key,
      String heroTag,
      String avatar,
      double size,
      double radius,
      Color color,
      GestureTapCallback onTap}) {
    return CAvatar._(
      key: key,
      avatar: avatar ?? "",
      size: size ?? ew(72),
      radius: radius,
      onTap: onTap,
      color: color,
      heroTag: heroTag,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (avatar == null || avatar.isEmpty)
      return Container(
        decoration: BoxDecoration(
          color: color ?? Style.pBackgroundColor,
          borderRadius: BorderRadius.all(Radius.circular(ew(6))),
        ),
        width: size,
        height: size,
      );
    Widget child = CachedNetworkImage(
      imageUrl: avatar,
      width: size,
      height: size,
      placeholder: (context, url) {
        return Container(
            width: size, height: size, color: color ?? Style.pBackgroundColor);
      },
    );

    if (heroTag != null && heroTag.isNotEmpty)
      child = Hero(tag: heroTag, child: child);

    if (radius != null)
      child = ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: child,
      );

    if (onTap != null)
      child = GestureDetector(
        onTap: onTap,
        child: child,
      );

    return child;
  }
}
