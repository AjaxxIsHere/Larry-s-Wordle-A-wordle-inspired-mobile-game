import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../pages/gamescreen/game_logic.dart';

final wordleGameProvider =
    StateNotifierProvider<WordleGameNotifier, WordleGameState>(
      (ref) => WordleGameNotifier(),
    );
