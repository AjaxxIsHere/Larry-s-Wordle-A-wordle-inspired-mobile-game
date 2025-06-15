import 'package:flutter_riverpod/flutter_riverpod.dart';

final easterEggProvider = StateNotifierProvider<EasterEggNotifier, bool>(
  (ref) => EasterEggNotifier(),
);

class EasterEggNotifier extends StateNotifier<bool> {
  EasterEggNotifier() : super(false);

  void triggerEasterEgg() {
    state = true;
    Future.delayed(const Duration(seconds: 2), () {
      state = false;
    });
  }
}

final easterEggWordProvider = Provider<String>((ref) {
  return "misty"; // Love you <3
});
