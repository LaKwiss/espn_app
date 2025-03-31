// espn_app/lib/screens/home_screen.dart
import 'dart:developer' as dev;
import 'package:espn_app/providers/league_async_notifier.dart';
import 'package:espn_app/providers/selected_league_notifier.dart';
import 'package:espn_app/widgets/home_screen_title.dart';
import 'package:espn_app/widgets/match_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // Import generated localizations

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Obtenir les traductions localisées
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Consumer(
        builder: (context, ref, child) {
          // Watch the provider to react to changes
          final eventsAsync = ref.watch(leagueAsyncProvider);

          final String fullTitle = ref.watch(selectedLeagueProvider).$1;
          final int spaceIndex = fullTitle.indexOf(' ');
          final String titleLine1 =
              spaceIndex > 0 ? fullTitle.substring(0, spaceIndex) : fullTitle;
          final String? titleLine2 =
              spaceIndex > 0 ? fullTitle.substring(spaceIndex + 1) : null;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HomeScreenTitle(titleLine1: titleLine1, titleLine2: titleLine2),

                // Debug info

                // Detailed events display with error handling
                eventsAsync.when(
                  data: (events) {
                    if (events.isEmpty) {
                      dev.log('Events list is empty in UI');
                      return Padding(
                        padding: const EdgeInsets.all(20),
                        child: Center(
                          child: Text(
                            l10n.noEventsAvailable, // Utiliser la clé de localisation
                            style: theme.textTheme.bodyLarge,
                          ),
                        ),
                      );
                    }

                    dev.log('Displaying ${events.length} events in UI');
                    return Column(
                      children:
                          events.map((event) {
                            dev.log('Rendering event: ${event.name}');
                            return MatchWidget(event: event);
                          }).toList(),
                    );
                  },
                  loading: () {
                    dev.log('UI shows loading state');
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: CircularProgressIndicator(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    );
                  },
                  error: (error, stack) {
                    dev.log('UI shows error: $error');
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Icon(
                              Icons.error,
                              color: theme.colorScheme.error,
                              size: 40,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              l10n.errorLoadingMatches,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.error,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            TextButton(
                              onPressed: () {
                                final result = ref.refresh(leagueAsyncProvider);
                                dev.log('Refresh result: $result');
                              },
                              child: Text(
                                l10n.tryAgain, // Utiliser la clé de localisation
                                style: theme.textTheme.labelLarge,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
