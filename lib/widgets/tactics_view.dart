import 'dart:developer';

import 'package:espn_app/models/event.dart';
import 'package:espn_app/models/formation_response.dart';
import 'package:espn_app/models/team.dart';
import 'package:espn_app/providers/formation_async_notifier.dart';
import 'package:espn_app/widgets/formation_visualizer.dart';
import 'package:espn_app/widgets/substitutes_list.dart';
import 'package:espn_app/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class TacticsView extends ConsumerWidget {
  final Event event;
  final Team homeTeam;
  final Team awayTeam;
  final VoidCallback onToggleView;

  const TacticsView({
    super.key,
    required this.event,
    required this.homeTeam,
    required this.awayTeam,
    required this.onToggleView,
  });

  String _extractLeagueId(String leagueUrl) {
    final uriParts = leagueUrl.split('/');
    for (int i = 0; i < uriParts.length; i++) {
      if (uriParts[i] == 'leagues' && i + 1 < uriParts.length) {
        String leagueWithParams = uriParts[i + 1];
        return leagueWithParams.split('?').first;
      }
    }
    return 'uefa.champions';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final leagueId = _extractLeagueId(event.league);
    final matchId = event.id;
    final homeTeamId = event.idTeam.$1;
    final awayTeamId = event.idTeam.$2;

    final homeFormationKey = '$matchId-$homeTeamId';
    final awayFormationKey = '$matchId-$awayTeamId';

    final formationState = ref.watch(formationAsyncProvider);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (formationState.value == null ||
          !formationState.value!.formationCache.containsKey(homeFormationKey) ||
          !formationState.value!.formationCache.containsKey(awayFormationKey)) {
        ref
            .read(formationAsyncProvider.notifier)
            .fetchMatchFormations(
              matchId: matchId,
              homeTeamId: homeTeamId,
              awayTeamId: awayTeamId,
              leagueId: leagueId,
            );

        ref
            .read(formationAsyncProvider.notifier)
            .fetchEnrichedPlayers(
              matchId: matchId,
              teamId: homeTeamId,
              leagueId: leagueId,
            );

        ref
            .read(formationAsyncProvider.notifier)
            .fetchEnrichedPlayers(
              matchId: matchId,
              teamId: awayTeamId,
              leagueId: leagueId,
            );
      }
    });

    return formationState.when(
      data: (state) {
        final homeFormation = state.formationCache[homeFormationKey];
        final awayFormation = state.formationCache[awayFormationKey];

        final homeEnrichedPlayers =
            state.enrichedPlayersCache[homeFormationKey] ?? [];
        final awayEnrichedPlayers =
            state.enrichedPlayersCache[awayFormationKey] ?? [];

        final homeStarters =
            homeEnrichedPlayers.where((p) => p.isStarter).toList();
        final awayStarters =
            awayEnrichedPlayers.where((p) => p.isStarter).toList();
        final homeSubstitutes =
            homeEnrichedPlayers.where((p) => !p.isStarter).toList();
        final awaySubstitutes =
            awayEnrichedPlayers.where((p) => !p.isStarter).toList();

        if (homeFormation == null ||
            awayFormation == null ||
            homeStarters.isEmpty ||
            awayStarters.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(l10n.loadingTacticsData),
              ],
            ),
          );
        }
        final homeColor = Colors.blue;
        final awayColor = Colors.red;

        final homeSubstitutions = _createSubstitutions(homeEnrichedPlayers);
        final awaySubstitutions = _createSubstitutions(awayEnrichedPlayers);

        return SingleChildScrollView(
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: FormationVisualizer(
                  formation: homeFormation.formationName,
                  players: homeStarters,
                  teamColor: homeColor,
                  teamName: homeTeam.name,
                  isHomeTeam: true,
                  onPlayerTap: (player) {
                    _showPlayerDetails(context, player, homeColor);
                  },
                ),
              ),

              SubstitutesList(
                substitutes: homeSubstitutes,
                substitutions: homeSubstitutions,
                teamColor: homeColor,
                teamName: homeTeam.name,
                onPlayerTap: (player) {
                  _showPlayerDetails(context, player, homeColor);
                },
              ),

              const SizedBox(height: 24),

              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: FormationVisualizer(
                  formation: awayFormation.formationName,
                  players: awayStarters,
                  teamColor: awayColor,
                  teamName: awayTeam.name,
                  isHomeTeam: false,
                  onPlayerTap: (player) {
                    _showPlayerDetails(context, player, awayColor);
                  },
                ),
              ),

              SubstitutesList(
                substitutes: awaySubstitutes,
                substitutions: awaySubstitutions,
                teamColor: awayColor,
                teamName: awayTeam.name,
                onPlayerTap: (player) {
                  _showPlayerDetails(context, player, awayColor);
                },
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
      loading:
          () => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(l10n.loadingTacticsData),
              ],
            ),
          ),
      error:
          (error, stackTrace) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(l10n.errorLoadingTactics(error.toString())),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    var data = ref.refresh(formationAsyncProvider);
                    log(data.value.toString());
                  },
                  child: Text(l10n.tryAgain),
                ),
              ],
            ),
          ),
    );
  }

  List<Substitution> _createSubstitutions(List<EnrichedPlayerEntry> players) {
    final substitutions = <Substitution>[];

    for (var player in players) {
      if (player.subbedOut && player.replacementId != null) {
        final replacement = players.firstWhere(
          (p) => p.playerId == player.replacementId,
          orElse:
              () => EnrichedPlayerEntry.fromPlayerEntry(PlayerEntry.empty()),
        );

        if (replacement.playerId != 0) {
          substitutions.add(
            Substitution(
              playerOut: player,
              playerIn: replacement,
              minute: player.subMinute,
            ),
          );
        }
      }
    }
    substitutions.sort((a, b) {
      final minuteA =
          int.tryParse(a.minute.replaceAll(RegExp(r'[^\d]'), '')) ?? 999;
      final minuteB =
          int.tryParse(b.minute.replaceAll(RegExp(r'[^\d]'), '')) ?? 999;
      return minuteA.compareTo(minuteB);
    });

    return substitutions;
  }

  void _showPlayerDetails(
    BuildContext context,
    EnrichedPlayerEntry player,
    Color teamColor,
  ) {
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                CircleAvatar(
                  backgroundColor: teamColor,
                  child: Text(
                    player.jerseyNumber,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    player.displayName,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${l10n.positionLabel}: ${player.positionName} (${player.positionAbbreviation})',
                ),
                const SizedBox(height: 8),
                if (player.subbedOut)
                  Text(l10n.substitutedOutAt(player.subMinute)),
                if (player.subbedIn)
                  Text(l10n.substitutedInAt(player.subMinute)),
                const SizedBox(height: 8),
                if (player.hasYellowCard)
                  Row(
                    children: [
                      const Icon(Icons.square, color: Colors.yellow, size: 16),
                      const SizedBox(width: 4),
                      Text(l10n.yellowCardLabel),
                    ],
                  ),
                if (player.hasRedCard)
                  Row(
                    children: [
                      const Icon(Icons.square, color: Colors.red, size: 16),
                      const SizedBox(width: 4),
                      Text(l10n.redCardLabel),
                    ],
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.closeButton),
              ),
            ],
          ),
    );
  }
}
