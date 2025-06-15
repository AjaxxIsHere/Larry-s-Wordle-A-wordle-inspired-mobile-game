import 'package:dynamic_background/domain/enums/scroller_shape.dart';
import 'package:dynamic_background/domain/enums/scroller_shape_offset.dart';
import 'package:dynamic_background/domain/models/color_schemes.dart';
import 'package:dynamic_background/domain/models/painter_data/scroller_painter_data.dart';
import 'package:dynamic_background/widgets/views/dynamic_bg.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wordle_clone/pages/gamescreen/game_screen.dart';
import 'package:wordle_clone/pages/homepage/settings.dart';
import 'package:wordle_clone/providers/game_provider.dart';
import 'package:wordle_clone/providers/theme_provider.dart';
import 'package:wordle_clone/services/word_picker.dart';
import 'package:wordle_clone/widgets/logo_widget.dart';
import 'package:wordle_clone/widgets/text_button.dart';
import 'package:wordle_clone/widgets/error_message.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:wordle_clone/providers/cell_state_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  bool _isLoading = false;
  bool _isUnlimitedLoading = false;

  @override
  Widget build(BuildContext context) {
    // Common button styles
    const double buttonHeight = 60;
    const double buttonWidth = 250;
    const double borderWidth = 2;
    const TextStyle buttonTextStyle = TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.bold,
      fontFamily: 'Rokkitt',
      color: Colors.black,
    );
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      body: DynamicBg(
        key: ValueKey(themeMode), // Force rebuild when themeMode changes
        painterData:
            themeMode == ThemeMode.light
                ? ScrollerPainterData(
                  shape: ScrollerShape.circles,
                  backgroundColor: ColorSchemes.gentleWhiteBg,
                  color: ColorSchemes.gentleWhiteFg,
                  shapeOffset: ScrollerShapeOffset.shiftAndMesh,
                )
                : ScrollerPainterData(
                  shape: ScrollerShape.circles,
                  backgroundColor: ColorSchemes.vibrantBlackFg,
                  // color: ColorSchemes.gentleBlackBg,
                  // backgroundColor: const Color.fromARGB(255, 81, 81, 81),
                  color: const Color.fromARGB(255, 45, 45, 45),
                  shapeOffset: ScrollerShapeOffset.shiftAndMesh,
                ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(height: 200), // Add spacing from the top
            LogoWidget(width: 400, height: 60),
            const SizedBox(height: 150), // Add spacing after the logo
            WordleAnimatedButton(
              borderColor: Colors.black,
              borderWidth: borderWidth,
              color: Colors.green,
              height: buttonHeight,
              width: buttonWidth,
              onPressed:
                  _isLoading
                      ? null
                      : () {
                        setState(() {
                          _isLoading = true;
                        });
                        _handleDailyChallengeButtonPress();
                      },
              child:
                  _isLoading
                      ? const SpinKitThreeBounce(color: Colors.black, size: 20)
                      : const Text("Daily Challenge", style: buttonTextStyle),
            ),
            const SizedBox(height: 20), // Add spacing
            WordleAnimatedButton(
              onPressed:
                  _isUnlimitedLoading
                      ? null
                      : () {
                        setState(() {
                          _isUnlimitedLoading = true;
                        });
                        _handleUnlimitedPlayButtonPress();
                      },
              height: buttonHeight,
              width: buttonWidth,
              color: Colors.yellow,
              borderColor: Colors.black,
              borderWidth: borderWidth,
              child:
                  _isUnlimitedLoading
                      ? const SpinKitThreeBounce(color: Colors.black, size: 20)
                      : const Text("Unlimited Play", style: buttonTextStyle),
            ),
            const SizedBox(height: 20), // Add spacing
            WordleAnimatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const Settings()),
                );
              },
              height: buttonHeight,
              width: buttonWidth,
              color: Colors.grey,
              borderColor: Colors.black,
              borderWidth: borderWidth,
              child: const Text("Settings", style: buttonTextStyle),
            ),
            const SizedBox(height: 20), // Add spacing
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Text(
                'Version 1.4.3',
                style: const TextStyle(
                  fontFamily: 'Rokkitt',
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleDailyChallengeButtonPress() async {
    try {
      final dailyWord = await WordHelper.getDailyWord();
      // Reset cell color state before navigating
      for (var row = 0; row < 6; row++) {
        for (var col = 0; col < 5; col++) {
          ref
              .read(cellStateProvider((row: row, col: col)).notifier)
              .setColor(Colors.transparent);
        }
      }
      // The wordleGameProvider.notifier.startNewGame is called in Gamescreen's initState,
      // and it handles loading the daily word and game state.
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) =>
                  Gamescreen(dailyWord: dailyWord, isDailyChallenge: true),
        ),
      );
    } catch (e) {
      showErrorDialog(
        context,
        '⚠️ Something went wrong! Please check your internet connection.',
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleUnlimitedPlayButtonPress() async {
    try {
      // Reset cell color state before navigating
      for (var row = 0; row < 6; row++) {
        for (var col = 0; col < 5; col++) {
          ref
              .read(cellStateProvider((row: row, col: col)).notifier)
              .setColor(Colors.transparent);
        }
      }
      final gameNotifier = ref.read(wordleGameProvider.notifier);
      await gameNotifier.startNewGame(
        isDailyChallenge: false,
      ); // This will generate a new random word
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Gamescreen(isDailyChallenge: false),
        ),
      );
    } catch (e) {
      showErrorDialog(
        context,
        '⚠️ Something went wrong! Please check your internet connection.',
      );
    } finally {
      setState(() {
        _isUnlimitedLoading = false;
      });
    }
  }
}
