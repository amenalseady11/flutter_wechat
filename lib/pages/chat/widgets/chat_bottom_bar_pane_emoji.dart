import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_wechat/util/adapter/adapter.dart';

List<String> emojis = '''
smile,blush,confused,anguished,cold_sweat,astonished,cry,joy,
disappointed_relieved,disappointed,anguished,confounded,angry,dizzy_face,expressionless,fearful,
flushed,frowning,grin,heart_eyes,heart_eyes_cat,hushed,imp,innocent,
kissing_closed_eyes,kissing_heart,laughing,neutral_face,no_mouth,open_mouth,pensive,persevere,
rage,relaxed,relieved,scream,sleeping,broken_heart,smirk,sob,
stuck_out_tongue_closed_eyes,sunglasses,sweat_smile,sweat,triumph,unamused,wink,yum,
cat,dog,bear,chicken,cow,ghost,hear_no_evil,koala,
mouse,airplane,ambulance,bike,bullettrain_side,bus,metro,oncoming_taxi,
walking,apple,banana,beer,birthday,cake,cherries,tada,
clap,fist,ok_hand,pray,thumbsup,thumbsdown,muscle,v
'''
    .replaceAll("\n", "")
    .split(",");

class ChatBottomBarPaneEmoji extends StatelessWidget {
  final ValueChanged<String> onTap;

  const ChatBottomBarPaneEmoji({Key key, this.onTap}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Container(
      height: ew(700),
      margin: EdgeInsets.only(right: ew(20)),
      width: double.maxFinite,
      child: GridView.count(
        primary: false,
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: false,
        crossAxisCount: 8,
        childAspectRatio: 1.4,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        children: List.generate(emojis.length, (i) {
          return IconButton(
              padding: EdgeInsets.all(ew(2)),
              icon: Image.asset(
                "assets/emojis/${emojis[i]}.png",
                fit: BoxFit.contain,
                width: ew(48),
              ),
              onPressed: () {
                if (this.onTap is! Function) return;
                this.onTap(emojis[i]);
              });
        }),
      ),
    );
  }
}
