import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:confetti/confetti.dart';
import 'package:wordle_clone/widgets/error_message.dart';
import 'package:wordle_clone/widgets/logo_widget.dart';
import 'package:wordle_clone/widgets/text_button.dart';
import 'package:wordle_clone/widgets/wordle_grid.dart';
import 'package:simple_animations/simple_animations.dart';
import 'package:wordle_clone/services/word_checker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'game_logic.dart';
import '../../providers/game_provider.dart';
import '../../widgets/keyboard.dart';
import '../../providers/easter_egg_provider.dart';
import '../../widgets/alert_dialog.dart';
import '../../providers/streak_provider.dart';
import '../../widgets/streak_dialog.dart';
import '../../providers/cell_state_provider.dart';
import 'package:flip_card/flip_card.dart'; // Import FlipCard

const int numRows = 6;
const int numCols = 5;
const Duration animationDuration = Duration(milliseconds: 500);

class Gamescreen extends ConsumerStatefulWidget {
  final String? dailyWord;
  final bool isDailyChallenge;

  const Gamescreen({super.key, this.dailyWord, this.isDailyChallenge = false});

  @override
  ConsumerState<Gamescreen> createState() => _GamescreenState();
}

class _GamescreenState extends ConsumerState<Gamescreen> {
  final List<List<TextEditingController>> _controllers = List.generate(
    6,
    (_) => List.generate(5, (_) => TextEditingController()),
  );
  final List<List<FocusNode>> _focusNodes = List.generate(
    6,
    (_) => List.generate(5, (_) => FocusNode()),
  );
  final List<List<GlobalKey>> _cellKeys = List.generate(
    6,
    (_) => List.generate(5, (_) => GlobalKey()),
  );
  // Add GlobalKeys for FlipCard
  final List<List<GlobalKey<FlipCardState>>> _flipCardKeys = List.generate(
    6,
    (_) => List.generate(5, (_) => GlobalKey<FlipCardState>()),
  );

  late ConfettiController _confettiController;
  final AudioPlayer _audioPlayer = AudioPlayer(); // Initialize AudioPlayer

  // Helper to get today's date as ISO string
  String get todayIso => DateTime.now().toIso8601String().split('T').first;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Add mounted check at the beginning of the async block
      if (!mounted) return;

      try {
        final prefs = await SharedPreferences.getInstance();
        final currentDate = DateTime.now().toIso8601String().split('T').first;

        // Always call startNewGame. It handles loading existing state or creating a new one.
        await ref
            .read(wordleGameProvider.notifier)
            .startNewGame(
              dailyWord: widget.dailyWord,
              isDailyChallenge: widget.isDailyChallenge,
            );

        // Add mounted check after the await, before accessing ref/state again
        if (!mounted) return;

        // After state is set (either loaded or new), update SharedPreferences
        // for the last played word/date, so the next launch knows.
        await prefs.setString('lastPlayedWord', widget.dailyWord ?? '');
        await prefs.setString('lastPlayedDate', currentDate);

        // Now, read the current state from the provider and update the UI controllers.
        // This part will execute regardless of whether a new game started or a state was loaded.
        final state = ref.read(wordleGameProvider);
        for (var row = 0; row < numRows; row++) {
          for (var col = 0; col < numCols; col++) {
            _controllers[row][col].text = state.guesses[row][col];
            // Set cell color state from loaded state
            ref
                .read(cellStateProvider((row: row, col: col)).notifier)
                .setColor(state.boxColors[row][col]);
          }
        }
        // Check mounted before calling setState
        if (mounted) {
          setState(() {}); // Trigger a rebuild to reflect the loaded/new state
        }

        // After the UI is updated, if it's a daily challenge and the game is over, show the dialog.
        if (widget.isDailyChallenge && state.gameOver) {
          // Check mounted before showing dialog (which uses context)
          if (mounted) {
            showDailyChallengeCompletedDialog(context);
          }
        }
      } on Exception catch (e) {
        debugPrint('Error accessing SharedPreferences: $e');
      }
    });
  }

  void _handleInput(int row, int col, String value) {
    final state = ref.read(wordleGameProvider);
    if (state.gameOver || row != state.currentRow) return;
    ref
        .read(wordleGameProvider.notifier)
        .setGuessLetter(
          row,
          col,
          value,
          isDailyChallenge: widget.isDailyChallenge,
        );
    _controllers[row][col].text =
        ref.read(wordleGameProvider).guesses[row][col];
    if (value.length == 1 && col < 4) {
      FocusScope.of(context).requestFocus(_focusNodes[row][col + 1]);
    } else if (value.isEmpty && col > 0) {
      FocusScope.of(context).requestFocus(_focusNodes[row][col - 1]);
    }
  }

  Future<void> _playRowAnimationsSequentially(
    int row,
    List<Color> colors,
  ) async {
    for (int i = 0; i < colors.length; i++) {
      final cellNotifier = ref.read(
        cellStateProvider((row: row, col: i)).notifier,
      );
      cellNotifier.setColor(colors[i]);
      // Trigger the custom bounce animation for the cell.
      cellNotifier.triggerAnimation();

      // Trigger the FlipCard animation directly here
      _flipCardKeys[row][i].currentState?.toggleCard();

      await Future.delayed(animationDuration);
    }
  }

  void _submitGuess() async {
    final state = ref.read(wordleGameProvider);
    if (state.gameOver) return;

    for (int i = 0; i < 5; i++) {
      ref
          .read(wordleGameProvider.notifier)
          .setGuessLetter(
            state.currentRow,
            i,
            _controllers[state.currentRow][i].text,
            isDailyChallenge: widget.isDailyChallenge,
          );
    }

    // Validate the word before submitting
    final userWord = _controllers[state.currentRow].map((c) => c.text).join();
    // final isValid = await WordHelper.isValidWord(userWord);
    final isValid = WordLoader.isValidWordLocally(userWord);
    if (!isValid) {
      showErrorDialog(context, '🚫 Invalid word. Please try again.');
      return;
    }

    // Easter egg logic using provider
    final easterEggWord = ref.read(easterEggWordProvider);
    if (userWord.toLowerCase() == easterEggWord.toLowerCase()) {
      ref.read(easterEggProvider.notifier).triggerEasterEgg();
    }

    var result = ref
        .read(wordleGameProvider.notifier)
        .submitGuess(isDailyChallenge: widget.isDailyChallenge);

    // --- Trigger cell color and animations sequentially based on color after guess ---
    final colors = ref.read(wordleGameProvider).boxColors[state.currentRow];
    await _playRowAnimationsSequentially(state.currentRow, colors);
    // ---------------------------------------------------------

    if (result == WordleGuessResult.correct) {
      _confettiController.play();
      _audioPlayer.play(AssetSource('sounds/winner.mp3')); // Play winner sound
      showErrorDialog(context, '🥳 Congratulations! You guessed the word!');
      // --- Streak logic for daily challenge ---
      if (widget.isDailyChallenge) {
        // Wait for streak provider to finish loading before incrementing
        final streakState = ref.read(streakProvider);
        if (!streakState.loading) {
          await ref.read(streakProvider.notifier).incrementStreak(todayIso);
          if (mounted) {
            showDailyChallengeCompletedDialog(context);
          }
        }
      }
    } else if (result == WordleGuessResult.failed) {
      final word = ref.read(wordleGameProvider).randomWord;
      showErrorDialog(context, '😓 Game Over! The word was $word');

      // --- Reset streak if daily challenge failed ---
      if (widget.isDailyChallenge) {
        await ref.read(streakProvider.notifier).resetStreak();
        await ref.read(streakProvider.notifier).recordLoss(todayIso);
        // Ensure mounted before showing dialog again if coming from async
        if (mounted) {
          showDailyChallengeCompletedDialog(context);
        }
      }
    } else if (result == WordleGuessResult.incorrect) {
      FocusScope.of(
        context,
      ).requestFocus(_focusNodes[ref.read(wordleGameProvider).currentRow][0]);
    }
  }

  void _handleKeyboardInput(String letter) {
    final state = ref.read(wordleGameProvider);
    if (state.gameOver) return;
    final row = state.currentRow;
    // Find first empty cell in current row
    final col = state.guesses[row].indexWhere((l) => l.isEmpty);
    if (col != -1) {
      ref.read(wordleGameProvider.notifier).setGuessLetter(row, col, letter);
      _controllers[row][col].text = letter;
      FocusScope.of(context).requestFocus(_focusNodes[row][col]);
    }
  }

  void _handleBackspace() {
    final state = ref.read(wordleGameProvider);
    if (state.gameOver) return;
    final row = state.currentRow;
    // Find last non-empty cell in current row
    int col = state.guesses[row].lastIndexWhere((l) => l.isNotEmpty);
    if (col != -1) {
      ref.read(wordleGameProvider.notifier).setGuessLetter(row, col, '');
      _controllers[row][col].clear();
      FocusScope.of(context).requestFocus(_focusNodes[row][col]);
    }
  }

  void _restartGame() async {
    try {
      await ref.read(wordleGameProvider.notifier).startNewGame();
      // Add mounted check after await
      if (!mounted) return;

      for (var row in _controllers) {
        for (var c in row) {
          c.clear();
        }
      }
      // Reset cell color state and flip cards back
      for (var row = 0; row < 6; row++) {
        for (var col = 0; col < 5; col++) {
          ref
              .read(cellStateProvider((row: row, col: col)).notifier)
              .setColor(Colors.transparent);
          // Toggle the card to ensure it's on the front face.
          // Since we can't directly check isFlipped, we just toggle it.
          // If it's on the back, it will flip to the front.
          // If it's already on the front, it will flip to the back, then immediately back to the front on the next frame (due to default behavior).
          // This ensures a reset visual state.
          _flipCardKeys[row][col].currentState?.toggleCard();
        }
      }
      // Check mounted before calling setState
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      // Show error message if unable to get a new word
      // Check mounted before showing dialog (which uses context)
      if (mounted) {
        showErrorDialog(
          context,
          '⚠️ Something went wrong! Please check your internet connection.',
        );
      }
    }
  }

  void _showStreakDialog() {
    showDialog(
      context: context,
      builder: (context) => const StreakDialog(), // No need to pass parameters
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    for (var row in _controllers) {
      for (var c in row) {
        c.dispose();
      }
    }
    for (var row in _focusNodes) {
      for (var f in row) {
        f.dispose();
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(wordleGameProvider);
    final mediaQuery = MediaQuery.of(context);
    final isPortrait = mediaQuery.size.height > mediaQuery.size.width;
    final width = mediaQuery.size.width;
    final gridWidth = isPortrait ? width * 0.95 : width * 0.6;
    final cellSize = (gridWidth / 6).clamp(36.0, 60.0);

    //------------------------------------------------------------------------------------------

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: LogoWidget(width: 180, height: 40),
        actions: [
          IconButton(
            icon: const Icon(Icons.emoji_events),
            tooltip: 'View Streak',
            onPressed: _showStreakDialog,
          ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              // dialog
              showDialog(
                context: context,
                builder:
                    (context) => AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color:
                              Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white
                                  : Colors.black,
                          width: 2,
                        ), // Add green border
                      ),
                      title: const Text(
                        'How to Play',
                        style: TextStyle(
                          fontFamily: 'Rokkitt',
                          fontWeight: FontWeight.bold,
                          fontSize: 30,
                        ),
                      ),
                      content: const Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text:
                                  'Guess larry\'s word within 6 attempts! Each letter will be highlighted based on its correctness:\n',
                            ),
                            TextSpan(
                              text: ' 🟩  Green : ',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(
                              text: 'Correct letter in the correct position\n',
                            ),
                            TextSpan(
                              text: ' 🟨 Yellow  : ',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(
                              text: 'Correct letter in the wrong position\n',
                            ),
                            TextSpan(
                              text: ' ⬛ Grey/Black  : ',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(text: 'Incorrect letter\n\n'),
                            TextSpan(
                              text:
                                  'Play the daily challenge to unlock a new word every day!\n',
                            ),
                            TextSpan(
                              text: 'Hint: Who\'s my favourite cat?',
                              style: TextStyle(
                                fontStyle: FontStyle.italic,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(
                            'OK',
                            style: TextStyle(
                              fontFamily: 'Rokkitt',
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color:
                                  Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.lightGreenAccent
                                      : Colors.green,
                            ),
                          ),
                        ),
                      ],
                    ),
              );
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isPortrait = constraints.maxHeight > constraints.maxWidth;
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;

          return SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                vertical: isPortrait ? height * 0.03 : height * 0.01,
                horizontal: isPortrait ? width * 0.01 : width * 0.05,
              ),
              child: Center(
                child: Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    // Confetti widget at the top center
                    ConfettiWidget(
                      confettiController: _confettiController,
                      blastDirectionality: BlastDirectionality.explosive,
                      shouldLoop: false,
                      emissionFrequency: 0.05,
                      numberOfParticles: 20,
                      maxBlastForce: 20,
                      minBlastForce: 8,
                      gravity: 0.3,
                    ),
                    // Main content
                    Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Top content
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              height:
                                  isPortrait ? height * 0.01 : height * 0.005,
                            ),
                            Text(
                              state.randomWord != null && state.gameOver
                                  ? 'Word: ${state.randomWord}'
                                  : 'Guess the Word!',
                              style: TextStyle(
                                fontSize:
                                    (isPortrait
                                        ? width * 0.06
                                        : height * 0.06) *
                                    MediaQuery.textScaleFactorOf(context),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(
                              height:
                                  isPortrait ? height * 0.02 : height * 0.01,
                            ),
                            WordleGrid(
                              state: state,
                              controllers: _controllers,
                              focusNodes: _focusNodes,
                              cellKeys: _cellKeys,
                              flipCardKeys:
                                  _flipCardKeys, // Pass the flipCardKeys
                              isDark:
                                  Theme.of(context).brightness ==
                                  Brightness.dark,
                              onInput: _handleInput,
                            ),
                            SizedBox(
                              height:
                                  isPortrait ? height * 0.02 : height * 0.01,
                            ),

                            if (state.gameOver && !widget.isDailyChallenge)
                              Container(
                                alignment: Alignment.center,
                                width: gridWidth,
                                child: WordleAnimatedButton(
                                  onPressed: _restartGame,
                                  width: 150,
                                  height: cellSize * 0.7,
                                  color: Colors.blueAccent,
                                  borderColor: Colors.black,
                                  borderWidth: 2,
                                  child: Text(
                                    "New Word",
                                    style: TextStyle(
                                      fontSize: cellSize * 0.3,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Rokkitt',
                                    ),
                                  ),
                                ),
                              ),
                            SizedBox(
                              height:
                                  isPortrait ? height * 0.02 : height * 0.01,
                            ),
                          ],
                        ),
                        // Keyboard at the bottom
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: isPortrait ? width * 0.98 : width * 0.7,
                          ),
                          child: WordleKeyboard(
                            onKeyTap: _handleKeyboardInput,
                            onBackspace: _handleBackspace,
                            onEnter:
                                state.gameOver ||
                                        state.guesses[state.currentRow].any(
                                          (l) => l.isEmpty,
                                        )
                                    ? null
                                    : _submitGuess,
                          ),
                        ),
                      ],
                    ),
                    Consumer(
                      builder: (context, ref, _) {
                        final showEasterEgg = ref.watch(easterEggProvider);
                        if (showEasterEgg) {
                          _audioPlayer.play(
                            AssetSource('sounds/meow.mp3'),
                          ); // Play meow sound
                        }
                        return PlayAnimationBuilder<double>(
                          tween: Tween(
                            begin: showEasterEgg ? 200 : 0,
                            end: showEasterEgg ? 0 : 200,
                          ),
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeInOut,
                          builder: (context, value, child) {
                            return Positioned(
                              bottom: value,
                              left: MediaQuery.of(context).size.width / 2 - 100,
                              child:
                                  showEasterEgg
                                      ? Image.asset(
                                        'assets/images/misty.png',
                                        width: 200,
                                        height: 400,
                                      )
                                      : const SizedBox.shrink(),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
