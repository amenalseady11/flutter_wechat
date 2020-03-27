import 'package:flutter/material.dart';
import 'package:flutter_wechat/util/adapter/adapter.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MenuItem {
  String key;
  String icon;
  String title;
  MenuItem(this.key, this.icon, this.title);
}

class MenuWidget extends StatefulWidget {
  final ValueChanged<String> onTap;
  final List<MenuItem> menus;

  const MenuWidget({Key key, this.onTap, this.menus = const []})
      : super(key: key);

  @override
  MenuWidgetState createState() => MenuWidgetState();
}

class MenuWidgetState extends State<MenuWidget>
    with SingleTickerProviderStateMixin {
  bool _visible = false;
  set visible(bool visible) {
    if (_visible == visible) return;
    this._visible = visible;
    if (mounted) setState(() {});
  }

  get visible => _visible;

  // 那个高亮的索引
  String _selectedKey = "";

  /// 是否需要动画
  bool _shouldAnimate = false;

  /// 缩放开始比例
  double _scaleBegin = 1.0;

  /// 缩放结束比例
  double _scaleEnd = 1.0;

  /// 动画控制器
  AnimationController _controller;

  /// 动画曲线
  CurvedAnimation _animation;

  @override
  void initState() {
    super.initState();

    // 配置动画
    _controller = new AnimationController(
        vsync: this, duration: Duration(milliseconds: 200));
    _animation =
        new CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    // 监听动画
    _controller.addStatusListener((AnimationStatus status) {
      // 到达结束状态时  要回滚到开始状态
      if (status == AnimationStatus.completed) {
        // 正向结束, 重置到当前
        _controller.reset();

        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (visible) {
      // 只有显示后 才需要缩放动画
      _shouldAnimate = true;
      _scaleBegin = _scaleEnd = 1.0;
    } else {
      _scaleBegin = 1.0;
      _scaleEnd = 0.5;
      // 处于开始阶段 且 需要动画
      if (_controller.isDismissed && _shouldAnimate) {
        _shouldAnimate = false;
        _controller.forward();
      } else {
        _scaleEnd = 1.0;
      }
    }

    return Offstage(
      offstage: !visible && _controller.isDismissed,
      child: InkWell(
        onTap: () {
          visible = false;
        },
        child: Container(
          padding: EdgeInsets.only(top: adapter.media.padding.top + ew(80)),
          constraints: BoxConstraints.expand(),
          color: Colors.transparent,
          child: AnimatedOpacity(
            opacity: visible ? 1.0 : 0.0,
            duration: Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: Stack(
              children: <Widget>[
                Positioned(
                  top: 0,
                  right: ew(16),
                  child: Image.asset(
                    'assets/images/icons/menu_up_arrow.png',
                    width: ew(53.0),
                    height: ew(32.0),
                  ),
                ),
                Positioned(
                  top: ew(32.0 - 8),
                  right: ew(6.0),
                  width: ew(290.0),
                  child: ScaleTransition(
                    scale: new Tween(begin: _scaleBegin, end: _scaleEnd)
                        .animate(_animation),
                    alignment: Alignment(0.8, -1.0),
                    child: _buildMenuWidget(),
                  ),
                  // child: _buildMenuWidget(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 构建menu部件
  Widget _buildMenuWidget() {
    List<Widget> children = [];

    for (var i = 0; i < widget.menus.length; i++) {
      if (i > 0)
        children.add(
            Divider(color: Colors.white30, height: ew(1), indent: ew(100)));

      children.add(_buildMenuItemWidget(widget.menus[i]));
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(ew(8)),
        color: Color(0xFF4C4C4C),
      ),
      child: Column(
        children: children,
//        children: <Widget>[
//          _buildMenuItemWidget(MenuItem("group_chat",
//              'assets/images/contacts/icons_filled_chats.svg', '发起群聊')),
//          _buildMenuItemWidget(MenuItem("group_chat1",
//              'assets/images/contacts/icons_filled_chats.svg', '发起群聊')),
//          Divider(color: Colors.white30, height: 1, indent: ew(100)),
//          _buildMenuItemWidget(MenuItem("group_chat2",
//              'assets/images/contacts/icons_filled_chats.svg', '发起群聊')),
//          Divider(color: Colors.white30, height: 1, indent: ew(60)),
//          _buildMenuItemWidget(MenuItem("group_chat3",
//              'assets/images/contacts/icons_filled_chats.svg', '发起群聊')),
//          Divider(color: Colors.white30, height: 1, indent: ew(60)),
//        ],
      ),
    );
  }

  /// 构建menu子部件
  Widget _buildMenuItemWidget(MenuItem menu) {
    return InkWell(
      onTap: () {
        visible = false;
        widget.onTap(menu.key);
      },
      onHighlightChanged: (bool highlight) {
        _selectedKey = highlight ? menu.key : "";
        setState(() {});
      },
      child: Container(
        decoration: BoxDecoration(
          color: _selectedKey == menu.key ? Colors.black26 : Colors.transparent,
          borderRadius: BorderRadius.circular(ew(8)),
        ),
        padding: EdgeInsets.only(left: ew(30), top: ew(24), bottom: ew(24)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            new SvgPicture.asset(menu.icon,
                width: ew(52.0), height: ew(52.0), color: Color(0xFFFFFFFF)),
            SizedBox(width: ew(20.0)),
            Text(
              menu.title,
              style: TextStyle(color: Colors.white, fontSize: sp(30.0)),
            ),
          ],
        ),
      ),
    );
  }
}
