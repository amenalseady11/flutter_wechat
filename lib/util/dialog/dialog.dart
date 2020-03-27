import 'package:flutter/material.dart';
import 'package:flutter_wechat/util/adapter/adapter.dart';
import 'package:flutter_wechat/util/style/style.dart';

Future<T> _showDialog<T>(BuildContext context,
    {@required String content, String title, List<Widget> actions}) async {
  List<Widget> children = [];

  var nextShowDivider = false;

  // 标题
  if (title != null && title.isNotEmpty) {
    children.add(Container(
      margin: EdgeInsets.only(top: ew(40)),
      padding: EdgeInsets.symmetric(horizontal: adapter.ew(20)),
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: adapter.sp(32), fontWeight: FontWeight.bold),
      ),
    ));
    nextShowDivider = true;
  }

  if (content != null && content.isNotEmpty) {
    // 需要添加分割线
//    if (nextShowDivider) {
//      nextShowDivider = false;
//      children.add(Divider(height: adapter.ew(1), color: Style.pDividerColor));
//    }

    // 添加正文
    children.add(Container(
      constraints: BoxConstraints(
        minHeight: adapter.ew(80),
      ),
      padding: EdgeInsets.symmetric(
        vertical: adapter.ew(title != null && title.isNotEmpty ? 50 : 60),
        horizontal: adapter.ew(34),
      ),
      child: Text(content,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.black87, fontSize: adapter.sp(30))),
    ));
    nextShowDivider = true;
  }

  if (actions != null || actions.length > 0) {
    // 需要添加分割线
    if (nextShowDivider) {
      nextShowDivider = false;
      children.add(Divider(height: adapter.ew(1), color: Style.pDividerColor));
    }

    children.add(Row(children: actions));
  }

  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return SimpleDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(adapter.ew(12)))),
          contentPadding: EdgeInsets.zero,
          children: children);
    },
  );
}

/// alert 窗口
/// [context] 上下文
/// [content] 正文
/// [title] 标题
/// [btnText]按钮文本
Future<void> alert(BuildContext context,
    {@required String content, String title, btnText: '确定'}) {
  return _showDialog<void>(context,
      content: content,
      title: title,
      actions: <Widget>[
        Expanded(
          child: FlatButton(
            child: Text(
              btnText ?? "确定",
              style: TextStyle(
                  color: Colors.red,
                  fontSize: adapter.sp(30),
                  fontWeight: FontWeight.bold),
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ]);
}

/// confirm 窗口
/// [context] 上下文
/// [content] 正文
/// [title] 标题
/// [okText]与[cancelText]按钮文本
Future<bool> confirm(BuildContext context,
    {@required String content, String title, okText: '确定', cancelText: '取消'}) {
  return _showDialog<bool>(context,
      content: content,
      title: title,
      actions: <Widget>[
        Expanded(
          child: FlatButton(
            child: Text(
              cancelText ?? '取消',
              style: TextStyle(
                  color: Colors.black87,
                  fontSize: adapter.sp(30),
                  fontWeight: FontWeight.bold),
            ),
            onPressed: () => Navigator.pop(context, false),
          ),
        ),
        SizedBox(
          width: adapter.ew(1.0),
          height: adapter.ew(80.0),
          child: VerticalDivider(
            width: adapter.ew(1.0),
            color: Style.pDividerColor,
          ),
        ),
        Expanded(
          child: FlatButton(
            child: Text(
              okText ?? '确定',
              style: TextStyle(
                  color: Colors.red,
                  fontSize: adapter.sp(30),
                  fontWeight: FontWeight.bold),
            ),
            onPressed: () => Navigator.pop(context, true),
          ),
        ),
      ]);
}
