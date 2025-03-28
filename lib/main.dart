// espn_app/lib/main.dart
import 'package:espn_app/providers/provider_factory.dart';
import 'package:espn_app/providers/settings_provider.dart';
import 'package:espn_app/screens/home_screen.dart';
import 'package:espn_app/screens/main_navigation_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // Import generated localizations

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]).then((_) {
    runApp(const ProviderScope(child: MyApp()));
  });
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Utiliser le thème depuis le provider
    final themeData = ref.watch(themeProvider);

    // Observer la locale depuis le provider
    final locale = ref.watch(localeProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // Utiliser la localisation pour le titre
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      theme: themeData,

      // Ajout des configurations de localisation
      localizationsDelegates:
          AppLocalizations.localizationsDelegates, // Utiliser le délégué généré
      supportedLocales:
          AppLocalizations.supportedLocales, // Utiliser les locales générées
      // localeResolutionCallback: L10n.localeResolutionCallback, // Peut être géré par Flutter
      locale: locale, // Utiliser la locale du provider

      routes: {
        '/': (context) => const MainNavigationScreen(),
        '/home': (context) => const HomeScreen(),
      },
      // Si vous n'utilisez pas onGenerateTitle, vous pouvez définir title ici :
      // title: 'ESPN App', // Ceci ne sera pas localisé
    );
  }
}
