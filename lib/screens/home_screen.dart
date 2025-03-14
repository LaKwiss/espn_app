import 'dart:developer' as dev;
import 'package:espn_app/providers/league_async_notifier.dart';
import 'package:espn_app/providers/selected_league_notifier.dart';
import 'package:espn_app/widgets/custom_app_bar.dart';
import 'package:espn_app/widgets/home_screen_title.dart';
import 'package:espn_app/widgets/match_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
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
                CustomAppBar(url: _getLinkByFullTitle(fullTitle)),
                HomeScreenTitle(titleLine1: titleLine1, titleLine2: titleLine2),

                // Debug info

                // Detailed events display with error handling
                eventsAsync.when(
                  data: (events) {
                    if (events.isEmpty) {
                      dev.log('Events list is empty in UI');
                      return const Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(
                          child: Text('No events available for this league'),
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
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(),
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
                            const Icon(
                              Icons.error,
                              color: Colors.red,
                              size: 40,
                            ),
                            const SizedBox(height: 16),
                            Text('Error: $error'),
                            TextButton(
                              onPressed: () {
                                final result = ref.refresh(leagueAsyncProvider);
                                dev.log('Refresh result: $result');
                              },
                              child: const Text('Try Again'),
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

_getLinkByFullTitle(String fullTitle) {
  switch (fullTitle) {
    case 'Bundesliga':
      return 'https://a.espncdn.com/i/leaguelogos/soccer/500/10.png';
    case 'LALIGA':
      return 'https://a.espncdn.com/i/leaguelogos/soccer/500/15.png';
    case 'French Ligue 1':
      return 'https://a.espncdn.com/i/leaguelogos/soccer/500/9.png';
    case 'Premier League':
      return 'https://a.espncdn.com/i/leaguelogos/soccer/500/23.png';
    case 'Italian Serie A':
      return 'https://a.espncdn.com/i/leaguelogos/soccer/500/12.png';
    case 'UEFA Europa League':
      return 'https://a.espncdn.com/i/leaguelogos/soccer/500/2310.png';
    case 'Champions League':
      return 'https://a.espncdn.com/i/leaguelogos/soccer/500/2.png';
    default:
      return 'https://a.espncdn.com/i/leaguelogos/soccer/500/2.png';
  }
}
