import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 适配方案
final _s = ScreenUtil();

/// 适配工具类
class Adapter {
  /// 工厂初始化
  /// [width]
  /// [height]
  /// [allowFontScaling]
  init(BuildContext context,
      {double width = 750.0,
      double height = 1334.0,
      bool allowFontScaling = true}) {
    ScreenUtil.init(context,
        width: width, height: height, allowFontScaling: allowFontScaling);
  }

  /// 获取[ScreenUtil]实例
  ScreenUtil get s => _s;

  /// 获取已配置等宽适配(设计尺寸1单位)
  get w1 => ew(1);

  /// 获取已配置等高的高度(设计尺寸1单位)
  get h1 => eh(1);

  /// 获取已配置适配的字体(设计尺寸1单位)
  get sp1 => sp(1);

  /// 等宽适配
  /// [px] 设计尺寸高度
  ew(double px) {
    if (px < 0) return _s.setWidth(_s.uiWidthPx + px);
    return _s.setWidth(px);
  }

  /// 等高适配
  /// [px] 设计尺寸高度
  eh(double px) {
    if (px < 0) return _s.setHeight(_s.uiHeightPx + px);
    _s.setHeight(px);
  }

  /// 获取适配字体大小
  /// [fontSize] 设计尺寸大小
  /// [allowFontScalingSelf] 是否缩放字体
  sp(double fontSize, {allowFontScalingSelf = true}) {
    return _s.setSp(fontSize, allowFontScalingSelf: allowFontScalingSelf);
  }

  MediaQueryData get media => ScreenUtil.mediaQueryData;
}

final adapter = Adapter();

/// 等宽适配
/// [px] 设计尺寸高度
double ew(double px) {
  return adapter.ew(px);
}

/// 等高适配
/// [px] 设计尺寸高度
double eh(double px) {
  return adapter.eh(px);
}

/// 获取适配字体大小
/// [fontSize] 设计尺寸大小
/// [allowFontScalingSelf] 是否缩放字体
double sp(double px, {allowFontScalingSelf = true}) {
  return adapter.sp(px, allowFontScalingSelf: allowFontScalingSelf);
}
