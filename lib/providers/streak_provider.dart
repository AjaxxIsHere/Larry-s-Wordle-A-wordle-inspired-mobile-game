import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final streakProvider = StateNotifierProvider<StreakNotifier, StreakState>(
  (ref) => StreakNotifier(),
);

class StreakState {
  final int streak;
  final Set<String> completedWinDays; // Days won
  final Set<String> completedLossDays; // Days lost
  final bool loading;

  StreakState({
    required this.streak,
    required this.completedWinDays,
    required this.completedLossDays,
    this.loading = false,
  });

  StreakState copyWith({
    int? streak,
    Set<String>? completedWinDays,
    Set<String>? completedLossDays,
    bool? loading,
  }) {
    // Debug: print copyWith arguments and result
    debugPrint(
      '[StreakState.copyWith] streak: $streak, completedWinDays: $completedWinDays, completedLossDays: $completedLossDays, loading: $loading',
    );
    return StreakState(
      streak: streak ?? this.streak,
      completedWinDays: completedWinDays ?? this.completedWinDays,
      completedLossDays: completedLossDays ?? this.completedLossDays,
      loading: loading ?? this.loading,
    );
  }
}

class StreakNotifier extends StateNotifier<StreakState> {
  static const _streakKey = 'streak';
  static const _completedWinDaysKey = 'completedWinDays';
  static const _completedLossDaysKey = 'completedLossDays';

  StreakNotifier()
    : super(
          StreakState(
            streak: 0,
            completedWinDays: {},
            completedLossDays: {},
            loading: true, // Initial state is loading
          ),
        ) {
    _load();
  }

  Future<void> _load() async {
    state = state.copyWith(loading: true);
    final prefs = await SharedPreferences.getInstance();
    final loadedStreak = prefs.getInt(_streakKey) ?? 0;
    final loadedWinDays =
        prefs.getStringList(_completedWinDaysKey)?.toSet() ?? <String>{};
    final loadedLossDays =
        prefs.getStringList(_completedLossDaysKey)?.toSet() ?? <String>{};

    debugPrint(
      '[StreakNotifier._load] Loaded streak: $loadedStreak, winDays: $loadedWinDays, lossDays: $loadedLossDays',
    );

    // Simplified _load: Just load the state. Streak calculation/reset
    // is handled by incrementStreak/resetStreak based on game outcomes.
    state = state.copyWith(
      streak: loadedStreak,
      completedWinDays: loadedWinDays,
      completedLossDays: loadedLossDays,
      loading: false,
    );
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_streakKey, state.streak);
    await prefs.setStringList(
      _completedWinDaysKey,
      state.completedWinDays.toList(),
    );
    await prefs.setStringList(
      _completedLossDaysKey,
      state.completedLossDays.toList(),
    );
    debugPrint(
      '[StreakNotifier._save] Saved streak: ${state.streak}, winDays: ${state.completedWinDays}, lossDays: ${state.completedLossDays}',
    );
  }

  Future<void> incrementStreak(String date) async {
    debugPrint('[StreakNotifier.incrementStreak] Called with date: $date');
    if (state.loading) {
      debugPrint('[StreakNotifier.incrementStreak] Still loading, waiting.');
      return;
    }

    bool changed = false;
    Set<String> newWinDays = Set<String>.from(state.completedWinDays);
    Set<String> newLossDays = Set<String>.from(state.completedLossDays);

    debugPrint(
      '[StreakNotifier.incrementStreak] Before: streak=${state.streak}, winDays=$newWinDays, lossDays=$newLossDays',
    );

    // If the current date is already in completedWinDays, don't increment streak,
    // but ensure it's removed from lossDays if it was there.
    if (newWinDays.contains(date)) {
      if (newLossDays.contains(date)) {
        newLossDays.remove(date);
        changed = true;
        debugPrint('[StreakNotifier.incrementStreak] Removed $date from lossDays.');
      }
      debugPrint('[StreakNotifier.incrementStreak] Already won today. No streak increment.');
    } else {
      // New win for today
      newWinDays.add(date);
      changed = true;
      debugPrint('[StreakNotifier.incrementStreak] Added $date to winDays.');

      // Check if yesterday was a win to continue streak
      final yesterday = DateTime.parse(date).subtract(const Duration(days: 1));
      final yesterdayIso = yesterday.toIso8601String().split('T').first;

      if (state.streak == 0 || newWinDays.contains(yesterdayIso)) {
        // If streak is 0 or yesterday was a win, increment streak
        state = state.copyWith(streak: state.streak + 1);
        changed = true;
        debugPrint('[StreakNotifier.incrementStreak] Streak incremented to ${state.streak}.');
      } else {
        // Streak broken, reset to 1
        state = state.copyWith(streak: 1);
        changed = true;
        debugPrint('[StreakNotifier.incrementStreak] Streak reset to 1 (yesterday not a win).');
      }

      // Remove from lossDays if it was a prior loss on the same day (shouldn't happen with win first)
      if (newLossDays.contains(date)) {
        newLossDays.remove(date);
        changed = true;
        debugPrint('[StreakNotifier.incrementStreak] Removed $date from lossDays (now a win).');
      }
    }

    if (changed) {
      state = state.copyWith(
        completedWinDays: newWinDays,
        completedLossDays: newLossDays,
      );
      await _save();
      debugPrint('[StreakNotifier.incrementStreak] After save: streak=${state.streak}, winDays=${state.completedWinDays}, lossDays=${state.completedLossDays}');
    } else {
      debugPrint('[StreakNotifier.incrementStreak] No changes made.');
    }
  }

  Future<void> resetStreak() async {
    if (state.streak != 0) {
      debugPrint(
        '[StreakNotifier.resetStreak] Resetting streak from ${state.streak} to 0',
      );
      state = state.copyWith(streak: 0);
      await _save();
    } else {
      debugPrint('[StreakNotifier.resetStreak] Streak already 0, nothing to reset.');
    }
  }

  Future<void> recordLoss(String date) async {
    bool changed = false;
    Set<String> newWinDays = Set<String>.from(state.completedWinDays);
    Set<String> newLossDays = Set<String>.from(state.completedLossDays);

    debugPrint(
      '[StreakNotifier.recordLoss] Before: winDays=$newWinDays, lossDays=$newLossDays, date=$date',
    );

    if (newWinDays.contains(date)) {
      newWinDays.remove(date);
      changed = true;
      debugPrint('[StreakNotifier.recordLoss] Removed $date from winDays');
    }
    if (!newLossDays.contains(date)) {
      newLossDays.add(date);
      changed = true;
      debugPrint('[StreakNotifier.recordLoss] Added $date to lossDays');
    }

    if (changed) {
      state = state.copyWith(
        completedWinDays: newWinDays,
        completedLossDays: newLossDays,
      );
      debugPrint(
        '[StreakNotifier.recordLoss] After update: winDays=${state.completedWinDays}, lossDays=${state.completedLossDays}',
      );
      await _save();
      debugPrint(
        '[StreakNotifier.recordLoss] After save: winDays=${state.completedWinDays}, lossDays=${state.completedLossDays}',
      );
    } else {
      debugPrint('[StreakNotifier.recordLoss] No changes made.');
    }
  }
}