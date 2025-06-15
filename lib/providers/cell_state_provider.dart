import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

class CellState {
  final Color color;
  final bool animate;
  const CellState({required this.color, this.animate = false});

  CellState copyWith({Color? color, bool? animate}) =>
      CellState(color: color ?? this.color, animate: animate ?? this.animate);
}

final cellStateProvider = StateNotifierProvider.family<
  CellStateNotifier,
  CellState,
  ({int row, int col})
>((ref, key) {
  return CellStateNotifier();
});

class CellStateNotifier extends StateNotifier<CellState> {
  CellStateNotifier() : super(const CellState(color: Colors.transparent));

  void setColor(Color color) {
    state = state.copyWith(color: color);
  }

  void triggerAnimation() {
    state = state.copyWith(animate: true);
  }

  void resetAnimation() {
    state = state.copyWith(animate: false);
  }
}
