import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Modèle pour les paramètres de l'application
class AppSettings {
  final bool notificationsEnabled;
  final bool darkModeEnabled;
  final String language;
  final bool cacheEnabled;

  AppSettings({
    this.notificationsEnabled = true,
    this.darkModeEnabled = false,
    this.language = 'English',
    this.cacheEnabled = true,
  });

  // Créer une copie avec des valeurs modifiées
  AppSettings copyWith({
    bool? notificationsEnabled,
    bool? darkModeEnabled,
    String? language,
    bool? cacheEnabled,
  }) {
    return AppSettings(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      darkModeEnabled: darkModeEnabled ?? this.darkModeEnabled,
      language: language ?? this.language,
      cacheEnabled: cacheEnabled ?? this.cacheEnabled,
    );
  }
}

// Notifier pour gérer les paramètres
class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier() : super(AppSettings());

  void toggleNotifications(bool value) {
    state = state.copyWith(notificationsEnabled: value);
  }

  void toggleDarkMode(bool value, BuildContext context) {
    state = state.copyWith(darkModeEnabled: value);
  }

  void setLanguage(String language) {
    state = state.copyWith(language: language);
  }

  void toggleCacheEnabled(bool value) {
    state = state.copyWith(cacheEnabled: value);
  }

  // Méthode pour simuler la suppression du cache
  Future<void> clearCache() async {
    // Ici, vous pourriez implémenter la logique réelle de suppression du cache
    // Pour l'instant, c'est juste une simulation
    await Future.delayed(const Duration(milliseconds: 500));

    // On ne modifie pas l'état ici car cela n'affecte pas les paramètres,
    // mais vous pourriez le faire si nécessaire
  }
}
