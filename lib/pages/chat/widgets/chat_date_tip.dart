import 'package:common_utils/common_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_wechat/providers/chat/chat.dart';
import 'package:flutter_wechat/util/adapter/adapter.dart';
import 'package:flutter_wechat/util/style/style.dart';

class ChatDateTip extends StatelessWidget {
  final int index;

  const ChatDateTip({Key key, this.index}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    var chat = ChatProvider.of(context, listen: false);
    var current = chat.messages[index + 1].sendTime;
    var next = chat.messages.length > index + 2
        ? chat.messages[index + 2].sendTime
        : DateTime.now();
    var duration = next.difference(current);
    if (duration.inMinutes < 5) return Container();
    duration = DateTime.now().difference(current);

    var hour = current.hour;
    var hours;
    if (hour < 6)
      hours = "凌晨";
    else if (hour < 8)
      hours = "早上";
    else if (hour < 11)
      hours = "上午";
    else if (hour < 14)
      hours = "中午";
    else if (hour < 18)
      hours = "下午";
    else if (hour < 20)
      hours = "傍晚";
    else if (hour < 24) hours = "晚上";

    var text;
    var days = duration.inDays;
    if (days < 1)
      text = DateUtil.formatDate(current, format: "$hours HH:mm");
    else if (days < 2)
      text = DateUtil.formatDate(current, format: "昨天 $hours HH:mm");
    else if (days < 7)
      text = DateUtil.getZHWeekDay(current).replaceFirst("星期", "周") +
          DateUtil.formatDate(current, format: " $hours HH:mm");
    else if (current.year == DateTime.now().year)
      text = DateUtil.formatDate(current, format: "MM月dd日 $hours HH:mm");
    else
      text = DateUtil.formatDate(current, format: "yyyy年MM月dd $hours HH:mm");
    return Container(
      padding: EdgeInsets.symmetric(vertical: ew(10)),
      child: Text(text,
          textAlign: TextAlign.center,
          style: TextStyle(color: Style.sTextColor, fontSize: sp(24))),
    );
  }
}
