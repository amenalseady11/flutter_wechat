import 'package:flutter/material.dart';

class Rotation extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const Rotation(
      {Key key, this.duration = const Duration(milliseconds: 1500), this.child})
      : super(key: key);
  @override
  _RotationState createState() => _RotationState();
}

class _RotationState extends State<Rotation>
    with SingleTickerProviderStateMixin {
  AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);

    _controller.repeat();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      alignment: Alignment.center,
      child: widget.child,
    );
  }
}
