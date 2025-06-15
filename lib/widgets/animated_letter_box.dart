import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flip_card/flip_card.dart';
import '../providers/cell_state_provider.dart';

class AnimatedLetterBox extends ConsumerStatefulWidget {
  final Widget child;
  final int row;
  final int col;
  final bool isDark;
  final bool enabled;
  final FocusNode focusNode;
  final TextEditingController controller;
  final void Function(String value) onInput;
  final GlobalKey<FlipCardState> flipCardKey; // Added flipCardKey

  const AnimatedLetterBox({
    super.key,
    required this.child,
    required this.row,
    required this.col,
    required this.isDark,
    required this.enabled,
    required this.focusNode,
    required this.controller,
    required this.onInput,
    required this.flipCardKey, 
  });

  @override
  ConsumerState<AnimatedLetterBox> createState() => _AnimatedLetterBoxState();
}

class _AnimatedLetterBoxState extends ConsumerState<AnimatedLetterBox> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final cellState = ref.watch(
      cellStateProvider((row: widget.row, col: widget.col)),
    );
    final isCellFocused = widget.focusNode.hasFocus;
    final isRowFocused = widget.enabled;
    Color borderColor = Colors.grey.shade400;
    double borderWidth = 2;
    if (isCellFocused) {
      borderColor = widget.isDark ? Colors.lightGreenAccent : Colors.green;
      borderWidth = 4;
    } else if (isRowFocused) {
      borderColor = widget.isDark ? Colors.white : Colors.black;
      borderWidth = 3;
    }

    Color textColor(Color tileColor) {
      if (!widget.isDark) return Colors.black;
      if (tileColor == Colors.transparent || tileColor == Colors.white) {
        return Colors.white;
      }
      return Colors.black;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: FlipCard(
        key: widget.flipCardKey, 
        flipOnTouch: false,
        direction: FlipDirection.VERTICAL,
        front: Container(
          decoration: BoxDecoration(
            color: cellState.color, 
            border: Border.all(color: borderColor, width: borderWidth),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: SizedBox(
            width: double.infinity,
            child: TextField(
              showCursor: false,
              readOnly: true,
              maxLength: 1,
              enabled: widget.enabled,
              focusNode: widget.focusNode,
              controller: widget.controller,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: textColor(cellState.color),
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: cellState.color, 
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                counterText: '',
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 2,
                  vertical: 0,
                ),
              ),
              onChanged: widget.onInput,
            ),
          ),
        ),
        back: Container(
          decoration: BoxDecoration(
            color: cellState.color,
            border: Border.all(color: borderColor, width: borderWidth),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: DefaultTextStyle(
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: textColor(cellState.color),
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
