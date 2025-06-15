import 'package:flip_card/flip_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'animated_letter_box.dart';

class WordleGrid extends ConsumerWidget {
  final dynamic state;
  final List<List<TextEditingController>> controllers;
  final List<List<FocusNode>> focusNodes;
  final List<List<GlobalKey>> cellKeys;
  final bool isDark;
  final void Function(int row, int col, String value) onInput;
  final List<List<GlobalKey<FlipCardState>>> flipCardKeys; // Add this

  const WordleGrid({
    super.key,
    required this.state,
    required this.controllers,
    required this.focusNodes,
    required this.cellKeys,
    required this.isDark,
    required this.onInput,
    required this.flipCardKeys, // Add this
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediaQuery = MediaQuery.of(context);
    final isPortrait = mediaQuery.size.height > mediaQuery.size.width;
    final width = mediaQuery.size.width;
    final height = mediaQuery.size.height;

    final gridWidth = isPortrait ? width * 0.95 : width * 0.6;
    final gridHeight = isPortrait ? height * 0.45 : height * 0.7;
    final cellSize = (gridWidth / 6).clamp(36.0, 60.0);
    final squareCellSize = cellSize.clamp(36.0, gridHeight / 6);

    return SizedBox(
      width: gridWidth,
      height: gridHeight,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(6, (row) {
          return Flexible(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (col) {
                return Padding(
                  padding: EdgeInsets.all(squareCellSize * 0.07),
                  child: SizedBox(
                    width: squareCellSize,
                    height: squareCellSize,
                    child: AnimatedLetterBox(
                      key: cellKeys[row][col],
                      row: row,
                      col: col,
                      isDark: isDark,
                      enabled: row == state.currentRow && !state.gameOver,
                      focusNode: focusNodes[row][col],
                      controller: controllers[row][col],
                      onInput: (value) => onInput(row, col, value),
                      flipCardKey: flipCardKeys[row][col],
                      child: Center(
                        child: Text(
                          state.guesses[row][col].toUpperCase(),
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          );
        }),
      ),
    );
  }
}
