import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wordle_clone/services/word_picker.dart';
import 'package:wordle_clone/services/word_checker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

enum WordleGuessResult { incomplete, correct, incorrect, failed }

class WordleGameState {
  final String? randomWord;
  final int currentRow;
  final bool gameOver;
  final bool won;
  final List<List<String>> guesses;
  final List<List<Color>> boxColors;

  WordleGameState({
    this.randomWord,
    this.currentRow = 0,
    this.gameOver = false,
    this.won = false,
    List<List<String>>? guesses,
    List<List<Color>>? boxColors,
  }) : guesses = guesses ?? List.generate(6, (_) => List.filled(5, '')),
       boxColors =
           boxColors ??
           List.generate(6, (_) => List.filled(5, Colors.transparent));

  WordleGameState copyWith({
    String? randomWord,
    int? currentRow,
    bool? gameOver,
    bool? won,
    List<List<String>>? guesses,
    List<List<Color>>? boxColors,
  }) {
    return WordleGameState(
      randomWord: randomWord ?? this.randomWord,
      currentRow: currentRow ?? this.currentRow,
      gameOver: gameOver ?? this.gameOver,
      won: won ?? this.won,
      guesses:
          guesses ?? this.guesses.map((row) => List<String>.from(row)).toList(),
      boxColors:
          boxColors ??
          this.boxColors.map((row) => List<Color>.from(row)).toList(),
    );
  }
}

class WordleGameNotifier extends StateNotifier<WordleGameState> {
  WordleGameNotifier() : super(WordleGameState());

  Future<WordleGameState?> startNewGame({
    String? dailyWord,
    bool isDailyChallenge = false,
  }) async {
    if (isDailyChallenge) {
      // Pass the potential new daily word to the loader
      final savedState = await _loadDailyChallengeState(
        newDailyWord: dailyWord,
      );
      if (savedState != null) {
        state = savedState;
        debugPrint('DEBUG (Notifier): Loaded existing daily challenge state.');
        return state; // Return the existing game state
      } else {
        debugPrint(
          'DEBUG (Notifier): No saved state or saved state invalidated. Starting fresh.',
        );
      }
    }

    final word = dailyWord ?? await WordHelper.getRandomFiveLetterWord();
    state = WordleGameState(randomWord: word, gameOver: false, won: false);

    if (isDailyChallenge) {
      debugPrint('DEBUG (Notifier): Saving new daily challenge state.');
      await _saveDailyChallengeState();
    }
    return null; // Return null for a new game
  }

  Future<void> _saveDailyChallengeState() async {
    final prefs = await SharedPreferences.getInstance();
    final stateJson = jsonEncode({
      'randomWord': state.randomWord,
      'currentRow': state.currentRow,
      'gameOver': state.gameOver,
      'won': state.won,
      'guesses': state.guesses,
      'boxColors':
          state.boxColors
              .map(
                (row) => row.map((color) => color.value).toList(),
              ) // FIX: Save full color value
              .toList(),
    });
    prefs.setString('dailyChallengeState', stateJson);
    prefs.setString('dailyChallengeDate', DateTime.now().toIso8601String());
    debugPrint(
      'DEBUG (Notifier): State saved: ${state.randomWord}, date: ${DateTime.now().toIso8601String()}',
    );
  }

  Future<WordleGameState?> _loadDailyChallengeState({
    String? newDailyWord,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final savedDateStr = prefs.getString('dailyChallengeDate');
    final stateJson = prefs.getString('dailyChallengeState');

    // If no state or date saved, or if it's a new day, clear and return null
    if (savedDateStr == null ||
        stateJson == null ||
        !_isSameDay(DateTime.parse(savedDateStr), DateTime.now())) {
      debugPrint(
        'DEBUG (Notifier): No saved state or old date. Clearing prefs.',
      );
      prefs.remove('dailyChallengeState');
      prefs.remove('dailyChallengeDate');
      return null;
    }

    final Map<String, dynamic> stateMap = jsonDecode(stateJson);
    final savedRandomWord = stateMap['randomWord'] as String?;

    // IMPORTANT ADDITION: If newDailyWord is provided and it doesn't match the saved word,
    // it means a new challenge word has arrived for the current day.
    // Invalidate the saved state and force a new game.
    if (newDailyWord != null && savedRandomWord != newDailyWord) {
      debugPrint(
        'DEBUG (Notifier): Daily word mismatch ($savedRandomWord vs $newDailyWord). Clearing prefs.',
      );
      prefs.remove('dailyChallengeState');
      prefs.remove('dailyChallengeDate');
      return null;
    }

    debugPrint(
      'DEBUG (Notifier): Loading saved state for word: $savedRandomWord',
    );
    return WordleGameState(
      randomWord: stateMap['randomWord'],
      currentRow: stateMap['currentRow'],
      gameOver: stateMap['gameOver'],
      won: stateMap['won'],
      guesses: List<List<String>>.from(
        stateMap['guesses'].map((row) => List<String>.from(row)),
      ),
      boxColors: List<List<Color>>.from(
        stateMap['boxColors'].map(
          (row) => List<Color>.from(row.map((color) => Color(color))),
        ),
      ),
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  void setGuessLetter(
    int row,
    int col,
    String value, {
    bool isDailyChallenge = false,
  }) {
    final newGuesses = state.guesses.map((r) => List<String>.from(r)).toList();
    newGuesses[row][col] = value.isNotEmpty ? value.trim().toUpperCase() : '';
    state = state.copyWith(guesses: newGuesses);

    // Save state only for daily challenge
    // FIX: Save on every letter input for daily challenge, not just full rows
    if (isDailyChallenge) {
      _saveDailyChallengeState();
    }
  }

  Future<void> loadSavedState() async {
    final prefs = await SharedPreferences.getInstance();
    final stateJson = prefs.getString('dailyChallengeState');
    if (stateJson != null) {
      final Map<String, dynamic> stateMap = jsonDecode(stateJson);
      state = WordleGameState(
        randomWord: stateMap['randomWord'],
        currentRow: stateMap['currentRow'],
        gameOver: stateMap['gameOver'],
        won: stateMap['won'],
        guesses: List<List<String>>.from(
          stateMap['guesses'].map((row) => List<String>.from(row)),
        ),
        boxColors: List<List<Color>>.from(
          stateMap['boxColors'].map(
            (row) => List<Color>.from(row.map((color) => Color(color))),
          ),
        ),
      );
    }
  }

  WordleGuessResult submitGuess({
    bool isDailyChallenge = false,
    bool isDark = false,
  }) {
    if (state.randomWord == null) {
      throw Exception(
        'Random word is not initialized. Start a new game first.',
      );
    }

    if (state.gameOver) return WordleGuessResult.failed;

    if (state.guesses[state.currentRow].any((letter) => letter.isEmpty)) {
      return WordleGuessResult.incomplete;
    }

    String guess = state.guesses[state.currentRow].join();
    List<Color> colors = List.filled(5, Colors.grey);
    List<bool> letterUsed = List.filled(5, false);

    Color getColor(Color color) {
      if (!isDark) return color;
      if (color == Colors.transparent) return Colors.black;
      if (color == Colors.white) return Colors.black;
      if (color == Colors.black) return Colors.white;
      if (color == Colors.green) return Colors.lightGreenAccent;
      if (color == Colors.amber) return Colors.amberAccent;
      if (color == Colors.grey) return Colors.grey[600]!;
      return color;
    }

    for (int i = 0; i < 5; i++) {
      if (guess[i] == state.randomWord![i]) {
        colors[i] = getColor(Colors.green);
        letterUsed[i] = true;
      }
    }
    for (int i = 0; i < 5; i++) {
      if (colors[i] == getColor(Colors.green)) continue;
      for (int j = 0; j < 5; j++) {
        if (!letterUsed[j] && guess[i] == state.randomWord![j]) {
          colors[i] = getColor(Colors.amber);
          letterUsed[j] = true;
          break;
        }
      }
    }
    for (int i = 0; i < 5; i++) {
      if (colors[i] != getColor(Colors.green) &&
          colors[i] != getColor(Colors.amber)) {
        colors[i] = getColor(Colors.grey);
      }
    }

    final newBoxColors =
        state.boxColors.map((r) => List<Color>.from(r)).toList();
    newBoxColors[state.currentRow] = colors;

    bool newGameOver = false;
    bool newWon = false;

    if (guess == state.randomWord) {
      newGameOver = true;
      newWon = true;
    } else if (state.currentRow == 5) {
      newGameOver = true;
    }

    state = state.copyWith(
      boxColors: newBoxColors,
      gameOver: newGameOver,
      won: newWon,
      currentRow: newGameOver ? state.currentRow : state.currentRow + 1,
    );

    if (isDailyChallenge) {
      _saveDailyChallengeState(); // Save state for daily challenge
    }

    if (newWon) return WordleGuessResult.correct;
    if (newGameOver) return WordleGuessResult.failed;
    return WordleGuessResult.incorrect;
  }

  // Example method to validate a word
  bool validateWord(String word) {
    return WordLoader.isValidWordLocally(word);
  }

  void saveDailyChallengeState() {
    _saveDailyChallengeState();
  }
}
