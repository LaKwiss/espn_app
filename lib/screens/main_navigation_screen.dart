// lib/screens/main_navigation_screen.dart
import 'dart:developer'; // Pour le log de débogage

import 'package:espn_app/providers/page_index_provider.dart';
import 'package:espn_app/providers/provider_factory.dart'; // Pour assetServiceProvider
import 'package:espn_app/providers/selected_league_notifier.dart'; // Pour selectedLeagueProvider
import 'package:espn_app/screens/calendar_screen.dart';
import 'package:espn_app/screens/home_screen.dart';
import 'package:espn_app/screens/settings_screen.dart';
import 'package:espn_app/widgets/custom_app_bar.dart'; // Importez CustomAppBar
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    // Initialise le PageController avec la page initiale basée sur le provider
    final initialPage = ref.read(pageIndexProvider);
    _pageController = PageController(initialPage: initialPage);

    // Met à disposition le PageController via le provider après la construction initiale
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(pageControllerProvider.notifier).state = _pageController;
      }
    });
  }

  @override
  void dispose() {
    // Nettoie le provider et le controller
    ref.read(pageControllerProvider.notifier).state = null;
    _pageController.dispose();
    super.dispose();
  }

  // Fonction pour obtenir l'URL du logo basée sur le state actuel
  String _getAppBarLogoUrl(WidgetRef ref) {
    final assetService = ref.watch(assetServiceProvider);
    final selectedLeagueState = ref.watch(selectedLeagueProvider);
    // Utilise le nom complet de la ligue stocké dans le state
    final leagueName = assetService.getLeagueNameFromCode(
      selectedLeagueState.$2,
    );
    return assetService.getLeagueLogoUrl(leagueName);
    // Alternative: utiliser _getLinkByFullTitle si nécessaire, mais getLeagueNameFromCode est plus fiable
    // return _getLinkByFullTitle(selectedLeagueState.$1);
  }

  @override
  Widget build(BuildContext context) {
    // Écoute les changements de pageIndexProvider pour mettre à jour la page si nécessaire
    ref.listen<int>(pageIndexProvider, (previous, next) {
      if (_pageController.hasClients && _pageController.page?.round() != next) {
        log('PageIndex changed to $next, animating PageView.'); // Debug
        _pageController.animateToPage(
          next,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });

    final theme = Theme.of(context);

    return Scaffold(
      // La CustomAppBar est maintenant dans la propriété appBar du Scaffold
      // Elle restera fixe en haut et ne scrollera pas avec le PageView
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(
          kToolbarHeight + 50,
        ), // Ajustez si LeagueSelector est visible par défaut
        child: CustomAppBar(
          url: _getAppBarLogoUrl(ref), // Obtient l'URL dynamiquement
          backgroundColor: theme.scaffoldBackgroundColor,
          // onArrowButtonPressed et iconOrientation ne sont plus nécessaires ici
          // car la CustomAppBar est maintenant utilisée différemment.
        ),
      ),
      // Le PageView contient les écrans et gère le swipe
      body: PageView(
        controller: _pageController,
        physics: const AlwaysScrollableScrollPhysics(),
        onPageChanged: (index) {
          // Met à jour le provider quand l'utilisateur swipe
          if (ref.read(pageIndexProvider) != index) {
            log("Page changed by swipe to: $index"); // Debug
            ref.read(pageIndexProvider.notifier).state = index;
          }
        },
        // Liste des écrans à afficher
        children: const [HomeScreen(), CalendarScreen(), SettingsScreen()],
      ),
    );
  }

  // Helper function (gardez-la si getLeagueNameFromCode ne suffit pas)
  String _getLinkByFullTitle(String fullTitle) {
    switch (fullTitle) {
      case 'Bundesliga':
        return 'https://a.espncdn.com/i/leaguelogos/soccer/500/10.png';
      case 'LALIGA':
        return 'https://a.espncdn.com/i/leaguelogos/soccer/500/15.png';
      case 'French Ligue 1':
      case 'Ligue 1': // Ajout pour correspondre au badge
        return 'https://a.espncdn.com/i/leaguelogos/soccer/500/9.png';
      case 'Premier League':
        return 'https://a.espncdn.com/i/leaguelogos/soccer/500/23.png';
      case 'Italian Serie A':
      case 'Serie A': // Ajout pour correspondre au badge
        return 'https://a.espncdn.com/i/leaguelogos/soccer/500/12.png';
      case 'UEFA Europa League':
      case 'Europa League': // Ajout pour correspondre au badge
        return 'https://a.espncdn.com/i/leaguelogos/soccer/500/2310.png';
      case 'Champions League':
        return 'https://a.espncdn.com/i/leaguelogos/soccer/500/2.png';
      default:
        // Essayer de trouver par code si le nom complet ne correspond pas
        final code = ref.read(selectedLeagueProvider).$2;
        final assetService = ref.read(assetServiceProvider);
        final leagueNameFromCode = assetService.getLeagueNameFromCode(code);
        return assetService.getLeagueLogoUrl(leagueNameFromCode);
      // return 'https://a.espncdn.com/i/leaguelogos/soccer/500/2.png'; // Fallback final
    }
  }
}
