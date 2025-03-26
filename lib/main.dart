import 'package:espn_app/l10n/l10n.dart';
import 'package:espn_app/providers/settings_provider.dart';
import 'package:espn_app/providers/theme_provider.dart';
import 'package:espn_app/screens/home_screen.dart';
import 'package:espn_app/screens/main_navigation_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      title: 'ESPN App',
      theme: themeData,

      // Ajout des configurations de localisation
      localizationsDelegates: L10n.localizationsDelegates,
      supportedLocales: L10n.supportedLocales,
      localeResolutionCallback: L10n.localeResolutionCallback,
      locale: locale, // Utiliser la locale du provider

      routes: {
        '/': (context) => const MainNavigationScreen(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}
