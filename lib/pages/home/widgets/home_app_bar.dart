import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_wechat/util/adapter/adapter.dart';
import 'package:flutter_wechat/widgets/rotation/rotation.dart';
import 'package:provider/provider.dart';

class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback onPressed;
  const HomeAppBar({Key key, this.title, this.onPressed}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
        duration: Duration(milliseconds: 200),
        opacity: title == "我" ? 0 : 1,
        child: _buildAppBar());
  }

  _buildAppBar() {
    return AppBar(
      centerTitle: false,
      elevation: 0,
      title: Row(
        children: <Widget>[
          Text(title, style: TextStyle(fontSize: sp(34))),
          Consumer<bool>(
            builder: (context, value, child) {
              return Offstage(
                offstage: !value,
                child: child,
              );
            },
            child: Rotation(
              child: Container(
                padding:
                    EdgeInsets.symmetric(horizontal: ew(10), vertical: ew(10)),
                child: SvgPicture.asset("assets/images/icons/loading.svg",
                    width: ew(32), height: ew(32), color: Colors.grey),
              ),
            ),
          )
        ],
      ),
      actions: <Widget>[
        IconButton(
          icon: SvgPicture.asset(
            'assets/images/icons/icons_outlined_add2.svg',
            color: Color(0xFF181818),
          ),
          onPressed: this.onPressed,
        )
      ],
    );
  }

  @override
  // TODO: implement preferredSize
  Size get preferredSize => Size.fromHeight(ew(80));
}
