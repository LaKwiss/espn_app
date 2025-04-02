import 'dart:developer';

import 'package:espn_app/providers/page_index_provider.dart';
import 'package:espn_app/providers/provider_factory.dart';
import 'package:espn_app/providers/selected_league_notifier.dart';
import 'package:espn_app/screens/calendar_screen.dart';
import 'package:espn_app/screens/home_screen.dart';
import 'package:espn_app/screens/settings_screen.dart';
import 'package:espn_app/widgets/custom_app_bar.dart';
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
    final initialPage = ref.read(pageIndexProvider);
    _pageController = PageController(initialPage: initialPage);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(pageControllerProvider.notifier).state = _pageController;
      }
    });
  }

  @override
  void dispose() {
    ref.read(pageControllerProvider.notifier).state = null;
    _pageController.dispose();
    super.dispose();
  }

  String _getAppBarLogoUrl(WidgetRef ref) {
    final assetService = ref.watch(assetServiceProvider);
    final selectedLeagueState = ref.watch(selectedLeagueProvider);
    final leagueName = assetService.getLeagueNameFromCode(
      selectedLeagueState.$2,
    );
    return assetService.getLeagueLogoUrl(leagueName);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(pageIndexProvider, (previous, next) {
      if (_pageController.hasClients && _pageController.page?.round() != next) {
        log('PageIndex changed to $next, animating PageView.');
        _pageController.animateToPage(
          next,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });

    final theme = Theme.of(context);

    final isLeagueSelectorVisible = ref.watch(leagueSelectorVisibilityProvider);

    final double extraHeight =
        isLeagueSelectorVisible.value == true ? 50.0 : 10.0;
    final double preferredHeight = kToolbarHeight + extraHeight;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(preferredHeight),
        child: CustomAppBar(
          url: _getAppBarLogoUrl(ref),
          backgroundColor: theme.scaffoldBackgroundColor,
        ),
      ),
      body: PageView(
        controller: _pageController,
        physics: const AlwaysScrollableScrollPhysics(),
        onPageChanged: (index) {
          if (ref.read(pageIndexProvider) != index) {
            log("Page changed by swipe to: $index");
            ref.read(pageIndexProvider.notifier).state = index;
          }
        },
        children: const [HomeScreen(), CalendarScreen(), SettingsScreen()],
      ),
    );
  }
}
