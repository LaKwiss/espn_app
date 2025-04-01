import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ColorsNotifier extends StateNotifier<List<Color>> {
  ColorsNotifier()
    : super([Colors.red, Colors.blue, Colors.green, Colors.yellow]);

  void addColor(Color color) {
    state = [...state, color];
  }

  Color? getColor(int index) {
    if (index >= 0 && index < state.length) {
      return state[index];
    }
    return null;
  }

  void updateColor(int index, Color newColor) {
    if (index >= 0 && index < state.length) {
      final newColors = List<Color>.from(state);
      newColors[index] = newColor;
      state = newColors;
    }
  }

  void deleteColor(int index) {
    if (index >= 0 && index < state.length) {
      final newColors = List<Color>.from(state);
      newColors.removeAt(index);
      state = newColors;
    }
  }

  void clearColors() {
    state = [];
  }
}
