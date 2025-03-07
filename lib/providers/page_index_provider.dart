import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider pour suivre l'index de la page actuelle
final pageIndexProvider = StateProvider<int>((ref) => 0);

// Provider pour accéder au contrôleur de page depuis n'importe où
final pageControllerProvider = StateProvider<PageController?>((ref) => null);
