import 'package:extended_text_field/extended_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_wechat/pages/chat/widgets/text_field/builder.dart';
import 'package:flutter_wechat/pages/chat/widgets/text_field/control.dart';
import 'package:flutter_wechat/util/adapter/adapter.dart';
import 'package:flutter_wechat/util/style/style.dart';

class ChatTextField extends StatefulWidget {
  final VoidCallback onPressed;
  final TextEditingController controller;

  const ChatTextField({Key key, this.onPressed, this.controller})
      : super(key: key);
  @override
  ChatTextFieldState createState() => ChatTextFieldState();
}

class ChatTextFieldState extends State<ChatTextField> {
  GlobalKey _inputKey = GlobalKey();
  get _text => widget.controller;

  MyExtendedMaterialTextSelectionControls
      _myExtendedMaterialTextSelectionControls =
      MyExtendedMaterialTextSelectionControls();
  MySpecialTextSpanBuilder _mySpecialTextSpanBuilder =
      MySpecialTextSpanBuilder(showAtBackground: true);
  FocusNode _inputFocusNode = FocusNode();

  void insertText(String text) {
    var value = _text.value;
    var start = value.selection.baseOffset;
    var end = value.selection.extentOffset;
    if (value.selection.isValid) {
      String newText = "";
      if (value.selection.isCollapsed) {
        if (end > 0) {
          newText += value.text.substring(0, end);
        }
        newText += text;
        if (value.text.length > end) {
          newText += value.text.substring(end, value.text.length);
        }
      } else {
        newText = value.text.replaceRange(start, end, text);
        end = start;
      }

      _text.value = value.copyWith(
          text: newText,
          selection: value.selection.copyWith(
              baseOffset: end + text.length, extentOffset: end + text.length));
    } else {
      _text.value = TextEditingValue(
          text: text,
          selection:
              TextSelection.fromPosition(TextPosition(offset: text.length)));
    }
  }

  void _manualDelete() {
    // delete by code
    final _value = _text.value;
    final selection = _value.selection;
    if (!selection.isValid) return;

    TextEditingValue value;
    final actualText = _value.text;
    if (selection.isCollapsed && selection.start == 0) return;
    final int start =
        selection.isCollapsed ? selection.start - 1 : selection.start;
    final int end = selection.end;

    value = TextEditingValue(
      text: actualText.replaceRange(start, end, ""),
      selection: TextSelection.collapsed(offset: start),
    );

    final oldTextSpan = _mySpecialTextSpanBuilder.build(_value.text);

    value = handleSpecialTextSpanDelete(value, _value, oldTextSpan, null);

    _text.value = value;
  }

  @override
  Widget build(BuildContext context) {
    return ExtendedTextField(
      key: _inputKey,
      focusNode: _inputFocusNode,
      controller: _text,
      textSelectionControls: _myExtendedMaterialTextSelectionControls,
      specialTextSpanBuilder: MySpecialTextSpanBuilder(
        showAtBackground: true,
      ),
      maxLines: null,
      cursorColor: Style.pTintColor,
      style: TextStyle(fontSize: sp(32)),
      decoration: InputDecoration(
        fillColor: Colors.white,
        filled: true,
        contentPadding:
            EdgeInsets.symmetric(horizontal: ew(20), vertical: ew(10)),
        border: InputBorder.none,
      ),
      onTap: () => widget.onPressed(),
      onChanged: (_) => widget.onPressed(),
    );
  }
}
