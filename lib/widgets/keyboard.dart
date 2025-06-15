import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/game_provider.dart';

enum KeyStatus { unused, correct, present, absent }

final keyboardStatusProvider = Provider<Map<String, KeyStatus>>((ref) {
  final state = ref.watch(wordleGameProvider);
  final Map<String, KeyStatus> status = {};
  // Initialize all keys as unused
  for (
    var codeUnit = 'A'.codeUnitAt(0);
    codeUnit <= 'Z'.codeUnitAt(0);
    codeUnit++
  ) {
    status[String.fromCharCode(codeUnit)] = KeyStatus.unused;
  }
  // Update status based on guesses and boxColors
  for (int row = 0; row < state.guesses.length; row++) {
    for (int col = 0; col < state.guesses[row].length; col++) {
      final letter = state.guesses[row][col];
      if (letter.isEmpty) continue;
      final color = state.boxColors[row][col];
      if (color == Colors.green) {
        status[letter] = KeyStatus.correct;
      } else if (color == Colors.amber) {
        // Only upgrade to present if not already correct
        if (status[letter] != KeyStatus.correct) {
          status[letter] = KeyStatus.present;
        }
      } else if (color == Colors.grey) {
        // Only mark absent if not already present/correct
        if (status[letter] != KeyStatus.correct &&
            status[letter] != KeyStatus.present) {
          status[letter] = KeyStatus.absent;
        }
      }
    }
  }
  return status;
});

class WordleKeyboard extends ConsumerWidget {
  final void Function(String letter) onKeyTap;
  final void Function()? onBackspace;
  final void Function()? onEnter;

  const WordleKeyboard({
    required this.onKeyTap,
    this.onBackspace,
    this.onEnter,
    super.key,
  });

  static const List<List<String>> _keys = [
    ['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P'],
    ['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L'],
    ['Z', 'X', 'C', 'V', 'B', 'N', 'M', '⌫'],
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final keyStatus = ref.watch(keyboardStatusProvider);

    // Responsive sizing
    final screenWidth = MediaQuery.of(context).size.width;
    final isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;
    final rowPadding = screenWidth * 0.01;
    final keyMinWidth = (screenWidth / 12).clamp(32.0, 56.0);
    final keyMinHeight =
        isPortrait
            ? (screenWidth / 11.5).clamp(38.0, 60.0)
            : (screenWidth / 18).clamp(32.0, 48.0);

    Color getKeyColor(String key) {
      switch (keyStatus[key]) {
        case KeyStatus.correct:
          return Colors.green;
        case KeyStatus.present:
          return Colors.amber;
        case KeyStatus.absent:
          return Colors.grey.shade400;
        default:
          return Colors.white;
      }
    }

    // Don't disable any key, always return false
    bool isKeyDisabled(String key) {
      return false;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Render the main keyboard rows
        ..._keys.map((row) {
          return Padding(
            padding: EdgeInsets.symmetric(vertical: rowPadding),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children:
                  row.map((key) {
                    if (key == '⌫') {
                      return Expanded(
                        flex: 2,
                        child: _KeyboardButton(
                          flex: 1,
                          label: '⌫',
                          color: Colors.blueGrey,
                          onTap: onBackspace,
                          minWidth: keyMinWidth * 1.2,
                          minHeight: keyMinHeight,
                          fontSize: keyMinHeight * 0.6,
                        ),
                      );
                    } else {
                      return Expanded(
                        child: _KeyboardButton(
                          flex: 1,
                          label: key,
                          color: getKeyColor(key),
                          onTap:
                              isKeyDisabled(key) ? null : () => onKeyTap(key),
                          minWidth: keyMinWidth,
                          minHeight: keyMinHeight,
                          fontSize: keyMinHeight * 0.6,
                        ),
                      );
                    }
                  }).toList(),
            ),
          );
        }),
        // ENTER button row at the bottom, fills width
        Padding(
          padding: EdgeInsets.only(top: rowPadding * 2),
          child: Row(
            children: [
              Expanded(
                child: _KeyboardButton(
                  flex: 1,
                  label: 'ENTER',
                  color: Colors.blueGrey,
                  onTap: onEnter,
                  minHeight: keyMinHeight * 1.1,
                  fontSize: keyMinHeight * 0.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _KeyboardButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback? onTap;
  final int flex;
  final double? minWidth;
  final double? minHeight;
  final double? fontSize;

  const _KeyboardButton({
    required this.label,
    required this.color,
    this.onTap,
    this.minWidth,
    this.minHeight,
    this.fontSize,
    required this.flex,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? Colors.white : Colors.black;

    // No Flexible/Expanded here, handled by parent Row
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2.0),
      child: SizedBox(
        width: minWidth,
        height: minHeight,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.black,
            minimumSize: Size(minWidth ?? 36, minHeight ?? 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
              side: BorderSide(color: borderColor, width: 2.0),
            ),
            elevation: 0,
            padding: EdgeInsets.zero,
          ),
          onPressed: onTap,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize),
              maxLines: 1,
            ),
          ),
        ),
      ),
    );
  }
}
