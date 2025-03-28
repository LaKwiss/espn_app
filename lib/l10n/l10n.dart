import 'package:flutter/material.dart';

// Ce fichier sera créé automatiquement une fois que vous aurez exécuté flutter gen-l10n
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class L10n {
  static final List<Locale> supportedLocales = [
    const Locale('en'),
    const Locale('fr'),
    const Locale('es'),
    const Locale('de'),
  ];

  static final List<LocalizationsDelegate> localizationsDelegates = [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  static LocaleResolutionCallback localeResolutionCallback = (
    locale,
    supportedLocales,
  ) {
    for (var supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale?.languageCode) {
        return supportedLocale;
      }
    }
    return supportedLocales.first;
  };

  static String getDisplayLanguage(String code) {
    switch (code) {
      case 'en':
        return 'English';
      case 'fr':
        return 'Français';
      case 'es':
        return 'Español';
      case 'de':
        return 'Deutsch';
      default:
        return 'English';
    }
  }
}
