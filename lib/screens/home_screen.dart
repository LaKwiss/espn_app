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
          // Utilisation de ref.read dans la fonction anonyme (ici nous utilisons ref.watch pour reconstruire le widget quand l'état change)
          final eventsAsync = ref.watch(leagueAsyncProvider);

          final String fullTitle = ref.watch(selectedLeagueProvider);
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
                CustomAppBar(
                  url: 'https://a.espncdn.com/i/leaguelogos/soccer/500/2.png',
                ),
                HomeScreenTitle(titleLine1: titleLine1, titleLine2: titleLine2),

                // Affichage des matchs depuis le provider
                eventsAsync.when(
                  data:
                      (events) => Column(
                        children:
                            events.map((event) {
                              return MatchWidget(event: event);
                            }).toList(),
                      ),
                  loading:
                      () => const Center(child: CircularProgressIndicator()),
                  error:
                      (error, stack) => Center(child: Text('Erreur: $error')),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
