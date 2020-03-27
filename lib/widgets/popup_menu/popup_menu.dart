import 'package:flutter/material.dart';
import 'package:flutter_wechat/util/adapter/adapter.dart';

class MyPopupMenuItem<T> extends PopupMenuEntry<T> {
  final T value;
  final bool enabled;
  @override
  final double height;
  final Widget child;
  final double width;

  const MyPopupMenuItem(
      {this.value,
      this.enabled = true,
      this.width,
      this.height,
      @required this.child});

  @override
  bool represents(T value) => value == this.value;

  @override
  PopupMenuItemState<T, MyPopupMenuItem<T>> createState() =>
      PopupMenuItemState<T, MyPopupMenuItem<T>>();
}

class PopupMenuItemState<T, W extends MyPopupMenuItem<T>> extends State<W> {
  @protected
  Widget buildChild() => widget.child;

  @protected
  void handleTap() {
    Navigator.pop<T>(context, widget.value);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    TextStyle style = theme.textTheme.subhead;
    if (!widget.enabled) style = style.copyWith(color: theme.disabledColor);

    Widget item = buildChild();
    if (!widget.enabled) {
      final bool isDark = theme.brightness == Brightness.dark;
      item = IconTheme.merge(
        data: IconThemeData(opacity: isDark ? 0.5 : 0.38),
        child: item,
      );
    }

    return InkWell(
      onTap: widget.enabled ? handleTap : null,
      child: Container(
        height: widget.height ?? ew(80),
        width: widget.width ?? ew(240.0),
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.symmetric(horizontal: ew(32)),
        child: item,
      ),
    );
  }
}
