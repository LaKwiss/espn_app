import 'package:espn_app/providers/selected_league_notifier.dart';
import 'package:espn_app/widgets/league_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:espn_app/providers/league_async_notifier.dart';

class LeagueSelector extends ConsumerWidget {
  const LeagueSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leagues = [
      LeagueItem.bundesliga(onTap: () => _onLeagueTap(context, ref, 'ger.1')),
      LeagueItem.laLiga(onTap: () => _onLeagueTap(context, ref, 'esp.1')),
      LeagueItem.ligue1(onTap: () => _onLeagueTap(context, ref, 'fra.1')),
      LeagueItem.premierLeague(
        onTap: () => _onLeagueTap(context, ref, 'eng.1'),
      ),
      LeagueItem.serieA(onTap: () => _onLeagueTap(context, ref, 'ita.1')),
      LeagueItem.europaLeague(
        onTap: () => _onLeagueTap(context, ref, 'uefa.europa'),
      ),
      LeagueItem.championsLeague(
        onTap: () => _onLeagueTap(context, ref, 'uefa.champions'),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: SizedBox(
        height: 40,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          itemCount: leagues.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: leagues[index],
            );
          },
        ),
      ),
    );
  }

  void _onLeagueTap(
    BuildContext context,
    WidgetRef ref,
    String leagueName,
  ) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$leagueName sélectionnée'),
        duration: Duration(seconds: 1),
      ),
    );
    ref.read(leagueAsyncProvider.notifier).fetchEvents(leagueName);
    final String fullName = await ref
        .read(leagueAsyncProvider.notifier)
        .getLeagueName(leagueName);
    ref.read(selectedLeagueProvider.notifier).selectLeague(fullName);
  }
}
