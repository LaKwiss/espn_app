import 'package:espn_app/providers/provider_factory.dart';
import 'package:espn_app/services/hive_cache_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Modèle pour les paramètres de l'application
class AppSettings {
  final bool notificationsEnabled;
  final bool darkModeEnabled;
  final String languageCode;
  final bool cacheEnabled;

  AppSettings({
    this.notificationsEnabled = true,
    this.darkModeEnabled = false,
    this.languageCode = 'en',
    this.cacheEnabled = true,
  });

  // Créer une copie avec des valeurs modifiées
  AppSettings copyWith({
    bool? notificationsEnabled,
    bool? darkModeEnabled,
    String? languageCode,
    bool? cacheEnabled,
  }) {
    return AppSettings(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      darkModeEnabled: darkModeEnabled ?? this.darkModeEnabled,
      languageCode: languageCode ?? this.languageCode,
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

  void setLanguage(String languageCode) {
    state = state.copyWith(languageCode: languageCode);
  }

  void toggleCacheEnabled(bool value) {
    state = state.copyWith(cacheEnabled: value);
  }

  // Méthode pour supprimer le cache
  Future<void> clearCache() async {
    try {
      // Get the HiveCacheService instance
      final hiveCacheService = HiveCacheService();

      // Clear all cache
      await hiveCacheService.clearAll();

      // Wait for a small delay for UI feedback
      await Future.delayed(const Duration(milliseconds: 500));
    } catch (e) {
      // Handle any error that might occur during cache clearing
      print('Error clearing cache: $e');
    }
  }
}

// Ajouter un provider pour la locale actuelle
final localeProvider = Provider<Locale>((ref) {
  final settings = ref.watch(settingsProvider);
  return Locale(settings.languageCode);
});
