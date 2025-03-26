import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ColorsNotifier extends StateNotifier<List<Color>> {
  ColorsNotifier()
    : super([Colors.red, Colors.blue, Colors.green, Colors.yellow]);

  // Create - Ajouter une nouvelle couleur
  void addColor(Color color) {
    state = [...state, color];
  }

  // Read - Obtenir une couleur par index
  Color? getColor(int index) {
    if (index >= 0 && index < state.length) {
      return state[index];
    }
    return null;
  }

  // Update - Modifier une couleur existante
  void updateColor(int index, Color newColor) {
    if (index >= 0 && index < state.length) {
      final newColors = List<Color>.from(state);
      newColors[index] = newColor;
      state = newColors;
    }
  }

  // Delete - Supprimer une couleur
  void deleteColor(int index) {
    if (index >= 0 && index < state.length) {
      final newColors = List<Color>.from(state);
      newColors.removeAt(index);
      state = newColors;
    }
  }

  // Vider la liste des couleurs
  void clearColors() {
    state = [];
  }
}
