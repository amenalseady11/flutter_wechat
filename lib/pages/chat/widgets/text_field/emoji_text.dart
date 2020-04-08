import 'package:extended_text_library/extended_text_library.dart';
import 'package:flutter/material.dart';
import 'package:flutter_wechat/util/adapter/adapter.dart';

///emoji/image text
class EmojiText extends SpecialText {
  static const String flag = "\":";
  final int start;
  EmojiText(TextStyle textStyle, {this.start})
      : super(EmojiText.flag, ":\"", textStyle);

  @override
  InlineSpan finishText() {
    var key1 = toString();
    var key = key1.substring(2, key1.length - 2 - 1);

    ///https://github.com/flutter/flutter/issues/42086
    /// widget span is not working on web
//    if (EmojiUitl.instance.emojiMap.containsKey(key) && !kIsWeb) {
    final double size = ew(40.0);
    final double margin = ew(2.0);

    ///fontSize 26 and text height =30.0
    //final double fontSize = 26.0;
    return ImageSpan(AssetImage("assets/emojis/$key.png"),
        actualText: key,
        imageWidth: size,
        imageHeight: size,
        start: start,
        fit: BoxFit.fill,
        margin: EdgeInsets.only(left: margin, top: margin, right: margin));

//    return TextSpan(text: toString(), style: textStyle);
  }
}

class EmojiUitl {
  final Map<String, String> _emojiMap = new Map<String, String>();

  Map<String, String> get emojiMap => _emojiMap;

  final String _emojiFilePath = "assets";

  static EmojiUitl _instance;
  static EmojiUitl get instance {
    if (_instance == null) _instance = new EmojiUitl._();
    return _instance;
  }

  EmojiUitl._() {
    _emojiMap["[love]"] = "$_emojiFilePath/love.png";
    _emojiMap["[sun_glasses]"] = "$_emojiFilePath/sun_glasses.png";
  }
}
