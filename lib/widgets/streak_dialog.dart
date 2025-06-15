import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/streak_provider.dart';

// Change StatelessWidget to ConsumerWidget
class StreakDialog extends ConsumerWidget {
  const StreakDialog({super.key}); // Remove constructor parameters

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Add WidgetRef ref
    // Watch the streakProvider to react to state changes
    final streakState = ref.watch(streakProvider);

    // Access the data directly from the watched state
    final streak = streakState.streak;
    final completedWinDays = streakState.completedWinDays;
    final completedLossDays = streakState.completedLossDays;
    final isLoading = streakState.loading; // Use the loading state

    // Debug: print current streak state
    debugPrint(
      '[StreakDialog] streak: $streak, completedWinDays: $completedWinDays, completedLossDays: $completedLossDays, loading: $isLoading',
    );

    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final isPortrait = height > width;
    final cellSize = (isPortrait ? width : height) / 10;

    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final weekDayOffset = firstDayOfMonth.weekday % 7;

    List<Widget> dayWidgets = [];
    for (int i = 0; i < weekDayOffset; i++) {
      dayWidgets.add(Container(width: cellSize, height: cellSize));
    }
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(now.year, now.month, day);
      final iso = date.toIso8601String().split('T').first;
      final isWin = completedWinDays.contains(iso);
      final isLoss = completedLossDays.contains(iso);

      dayWidgets.add(
        Container(
          width: cellSize,
          height: cellSize,
          margin: EdgeInsets.all(cellSize * 0.05),
          decoration: BoxDecoration(
            color:
                isWin
                    ? Colors.green.withOpacity(0.8)
                    : isLoss
                    ? Colors.red.withOpacity(0.8) // Color for loss
                    : Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(cellSize * 0.2),
            border: Border.all(
              color: isWin ? Colors.green : (isLoss ? Colors.red : Colors.grey),
              width: 2,
            ),
          ),
          child: Center(
            child:
                isWin
                    ? Icon(
                      Icons.check,
                      color: Colors.white,
                      size: cellSize * 0.6,
                    )
                    : isLoss
                    ? Icon(
                      Icons.close, 
                      color: Colors.white,
                      size: cellSize * 0.6,
                    )
                    : Text(
                      '$day',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: cellSize * 0.4,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
          ),
        ),
      );
    }

    // Show a loading indicator if data is still loading
    if (isLoading) {
      return AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading streak data...'),
          ],
        ),
      );
    }

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color:
              Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black,
          width: 2,
        ),
      ),
      title: Row(
        children: [
          Icon(Icons.emoji_events, color: Colors.orange, size: cellSize * 0.7),
          SizedBox(width: 8),
          Text(
            'Streak',
            style: TextStyle(
              fontFamily: 'Rokkitt',
              fontWeight: FontWeight.bold,
              fontSize: cellSize * 0.55,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Current Streak: $streak',
              style: TextStyle(
                fontSize: cellSize * 0.4,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: cellSize * 0.2),
            Text(
              DateFormat.yMMMM().format(now),
              style: TextStyle(
                fontSize: cellSize * 0.3,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: cellSize * 0.1),
            Wrap(spacing: 0, runSpacing: 0, children: dayWidgets),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Close',
            style: TextStyle(
              fontFamily: 'Rokkitt',
              fontWeight: FontWeight.bold,
              fontSize: cellSize * 0.55,
              color:
                  Theme.of(context).brightness == Brightness.dark
                      ? Colors.lightGreenAccent
                      : Colors.green,
            ),
          ),
        ),
      ],
    );
  }
}
