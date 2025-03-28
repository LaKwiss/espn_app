// espn_app/lib/screens/main_navigation_screen.dart
import 'dart:developer';

import 'package:espn_app/screens/calendar_screen.dart';
import 'package:espn_app/screens/home_screen.dart';
import 'package:espn_app/providers/page_index_provider.dart';
import 'package:espn_app/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Pas de texte directement visible dans ce widget, donc pas besoin d'importer AppLocalizations ici.

class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  ConsumerState<MainNavigationScreen> createState() =>
      _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);

    // Mettre le contrôleur dans le provider pour qu'il soit accessible globalement
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(pageControllerProvider.notifier).state = _pageController;
    });
  }

  @override
  void dispose() {
    // Nettoyer le provider lors de la destruction du widget
    ref.read(pageControllerProvider.notifier).state = null;
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics:
            const AlwaysScrollableScrollPhysics(), // S'assurer que la page est bien balayable
        onPageChanged: (index) {
          // Update the current page index in the provider
          ref.read(pageIndexProvider.notifier).state = index;
          log("Page changed to: $index"); // Debug (pas besoin de localiser)
        },
        // Les écrans contenus (HomeScreen, CalendarScreen, SettingsScreen)
        // gèreront leur propre localisation.
        children: const [HomeScreen(), CalendarScreen(), SettingsScreen()],
      ),
    );
  }
}
