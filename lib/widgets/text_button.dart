// Shout out to Emadeddin-eibo and for the Animated Button
// link: https://github.com/Emadeddin-eibo/animated_button

import 'package:flutter/material.dart';

class WordleAnimatedButton extends StatefulWidget {
  final Color color;
  final Widget child;
  final bool enabled;
  final double width;
  final int duration;
  final double height;
  final Color disabledColor;
  final double borderRadius;
  final VoidCallback? onPressed;
  final ShadowDegree shadowDegree;
  final Color? borderColor;
  final double? borderWidth;

  const WordleAnimatedButton({
    super.key,
    required this.child,
    this.onPressed, 
    this.height = 40,
    this.width = 140,
    this.duration = 70,
    this.enabled = true,
    this.borderRadius = 12,
    this.color = Colors.blue,
    this.disabledColor = Colors.grey,
    this.shadowDegree = ShadowDegree.light,
    this.borderColor,
    this.borderWidth,
  });

  @override
  WordleAnimatedButtonState createState() => WordleAnimatedButtonState();
}

class WordleAnimatedButtonState extends State<WordleAnimatedButton> {
  static const Curve _curve = Curves.easeIn;
  static const double _shadowHeight = 4;
  double _position = 4;

  @override
  Widget build(BuildContext context) {
    final double height = widget.height - _shadowHeight;

    return GestureDetector(
      // Now onTapDown, onTapUp, onTapCancel can be null if onPressed is null
      onTapDown: widget.enabled && widget.onPressed != null ? _pressed : null,
      onTapUp: widget.enabled && widget.onPressed != null ? _unPressedOnTapUp : null,
      onTapCancel: widget.enabled && widget.onPressed != null ? _unPressed : null,
      // width here is required for centering the button in parent
      child: SizedBox(
        width: widget.width,
        height: height + _shadowHeight,
        child: Stack(
          children: <Widget>[
            // background shadow serves as drop shadow
            // width is necessary for bottom shadow
            Positioned(
              bottom: 0,
              child: Container(
                height: height,
                width: widget.width,
                decoration: BoxDecoration(
                  color:
                      widget.enabled
                          ? darken(widget.color, widget.shadowDegree)
                          : darken(widget.disabledColor, widget.shadowDegree),
                  borderRadius: _getBorderRadius(),
                  border:
                      widget.borderColor != null && widget.borderWidth != null
                          ? Border.all(
                            color: widget.borderColor!,
                            width: widget.borderWidth!,
                          )
                          : null,
                ),
              ),
            ),
            AnimatedPositioned(
              curve: _curve,
              duration: Duration(milliseconds: widget.duration),
              bottom: _position,
              child: Container(
                height: height,
                width: widget.width,
                decoration: BoxDecoration(
                  color: widget.enabled ? widget.color : widget.disabledColor,
                  borderRadius: _getBorderRadius(),
                  border:
                      widget.borderColor != null && widget.borderWidth != null
                          ? Border.all(
                            color: widget.borderColor!,
                            width: widget.borderWidth!,
                          )
                          : null,
                ),
                child: Center(child: widget.child),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _pressed(_) {
    setState(() {
      _position = 0;
    });
  }

  void _unPressedOnTapUp(_) => _unPressed();

  void _unPressed() {
    setState(() {
      _position = 4;
    });
    // Call onPressed only if it's not null and enabled
    if (widget.enabled && widget.onPressed != null) { // <<< Added null check
      widget.onPressed!(); // <<< Use ! to assert non-null
    }
  }

  BorderRadius? _getBorderRadius() {
    return BorderRadius.circular(widget.borderRadius);
  }
}

Color darken(Color color, ShadowDegree degree) {
  double amount = degree == ShadowDegree.dark ? 0.3 : 0.12;
  final hsl = HSLColor.fromColor(color);
  final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));

  return hslDark.toColor();
}

enum ShadowDegree { light, dark }