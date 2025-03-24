// lib/widgets/tactics_view.dart
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

/// Widget pour afficher les tactiques d'un match
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

  /// Extrait l'ID de la ligue à partir de l'URL de la ligue
  String _extractLeagueId(String leagueUrl) {
    final uriParts = leagueUrl.split('/');
    for (int i = 0; i < uriParts.length; i++) {
      if (uriParts[i] == 'leagues' && i + 1 < uriParts.length) {
        String leagueWithParams = uriParts[i + 1];
        return leagueWithParams.split('?').first;
      }
    }
    return 'uefa.champions'; // Valeur par défaut
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Extraire les identifiants nécessaires
    final leagueId = _extractLeagueId(event.league);
    final matchId = event.id;
    final homeTeamId = event.idTeam.$1;
    final awayTeamId = event.idTeam.$2;

    // Clés de cache pour les formations et joueurs
    final homeFormationKey = '$matchId-$homeTeamId';
    final awayFormationKey = '$matchId-$awayTeamId';

    // Observer l'état du provider
    final formationState = ref.watch(formationAsyncProvider);

    // Initialiser la récupération des données si ce n'est pas déjà fait
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

        // Pré-charger les données enrichies des joueurs
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
        // Récupérer les données de formation si disponibles
        final homeFormation = state.formationCache[homeFormationKey];
        final awayFormation = state.formationCache[awayFormationKey];

        // Récupérer les données enrichies des joueurs si disponibles
        final homeEnrichedPlayers =
            state.enrichedPlayersCache[homeFormationKey] ?? [];
        final awayEnrichedPlayers =
            state.enrichedPlayersCache[awayFormationKey] ?? [];

        // Filtrer pour obtenir les titulaires et remplaçants
        final homeStarters =
            homeEnrichedPlayers.where((p) => p.isStarter).toList();
        final awayStarters =
            awayEnrichedPlayers.where((p) => p.isStarter).toList();
        final homeSubstitutes =
            homeEnrichedPlayers.where((p) => !p.isStarter).toList();
        final awaySubstitutes =
            awayEnrichedPlayers.where((p) => !p.isStarter).toList();

        // Si les données ne sont pas encore disponibles
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
                const Text('Chargement des données tactiques...'),
              ],
            ),
          );
        }

        // Déterminer les couleurs des équipes (pourrait être plus sophistiqué)
        final homeColor = Colors.blue;
        final awayColor = Colors.red;

        // Créer les listes de substitutions
        final homeSubstitutions = _createSubstitutions(homeEnrichedPlayers);
        final awaySubstitutions = _createSubstitutions(awayEnrichedPlayers);

        return SingleChildScrollView(
          child: Column(
            children: [
              // Bouton pour basculer entre la vue tactique et la vue des événements

              // Formation de l'équipe à domicile
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
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

              // Remplaçants de l'équipe à domicile
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

              // Formation de l'équipe à l'extérieur
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
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

              // Remplaçants de l'équipe à l'extérieur
              SubstitutesList(
                substitutes: awaySubstitutes,
                substitutions: awaySubstitutions,
                teamColor: awayColor,
                teamName: awayTeam.name,
                onPlayerTap: (player) {
                  _showPlayerDetails(context, player, awayColor);
                },
              ),

              // Espace en bas pour le défilement
              const SizedBox(height: 32),
            ],
          ),
        );
      },
      loading:
          () => const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Chargement des données tactiques...'),
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
                Text('Erreur: $error'),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    // Réessayer de charger les données
                    var data = ref.refresh(formationAsyncProvider);
                    log(data.value.toString());
                  },
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          ),
    );
  }

  /// Crée les substitutions à partir des données des joueurs
  List<Substitution> _createSubstitutions(List<EnrichedPlayerEntry> players) {
    final substitutions = <Substitution>[];

    // Trouver les joueurs qui sont sortis
    for (var player in players) {
      if (player.subbedOut && player.replacementId != null) {
        // Trouver le joueur entrant correspondant
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

    return substitutions;
  }

  /// Affiche une boîte de dialogue avec les détails du joueur
  void _showPlayerDetails(
    BuildContext context,
    EnrichedPlayerEntry player,
    Color teamColor,
  ) {
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
                Text(player.displayName),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Position: ${player.positionName}'),
                const SizedBox(height: 8),
                if (player.subbedOut) Text('Remplacé à la ${player.subMinute}'),
                if (player.subbedIn)
                  Text('Entré en jeu à la ${player.subMinute}'),
                const SizedBox(height: 8),
                if (player.hasYellowCard)
                  const Row(
                    children: [
                      Icon(Icons.square, color: Colors.yellow, size: 16),
                      SizedBox(width: 4),
                      Text('Carton jaune'),
                    ],
                  ),
                if (player.hasRedCard)
                  const Row(
                    children: [
                      Icon(Icons.square, color: Colors.red, size: 16),
                      SizedBox(width: 4),
                      Text('Carton rouge'),
                    ],
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Fermer'),
              ),
            ],
          ),
    );
  }
}
