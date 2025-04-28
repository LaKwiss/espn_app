import 'package:espn_app/models/hive_cache_entry.dart';
import 'package:espn_app/providers/provider_factory.dart';
import 'package:espn_app/providers/settings_provider.dart';
import 'package:espn_app/screens/home_screen.dart';
import 'package:espn_app/screens/main_navigation_screen.dart';
import 'package:espn_app/services/hive_cache_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  Hive.registerAdapter(HiveCacheEntryAdapter());

  await HiveCacheService.init();

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
    final themeData = ref.watch(themeProvider);

    final locale = ref.watch(localeProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,

      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      theme: themeData,

      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,

      routes: {
        '/': (context) => const MainNavigationScreen(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}
