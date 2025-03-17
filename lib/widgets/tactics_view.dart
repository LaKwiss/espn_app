import 'package:espn_app/models/event.dart';
import 'package:espn_app/models/formation_response.dart';
import 'package:espn_app/models/team.dart';
import 'package:espn_app/providers/formation_async_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

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

        if (homeFormation == null ||
            awayFormation == null ||
            homeEnrichedPlayers.isEmpty ||
            awayEnrichedPlayers.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final homeColor = Colors.blue;
        final awayColor = Colors.red;
        final homeStarters =
            homeEnrichedPlayers.where((p) => p.isStarter).toList();
        final awayStarters =
            awayEnrichedPlayers.where((p) => p.isStarter).toList();
        final homeSubstitutes =
            homeEnrichedPlayers.where((p) => !p.isStarter).toList();
        final awaySubstitutes =
            awayEnrichedPlayers.where((p) => !p.isStarter).toList();

        // Utiliser un seul SingleChildScrollView pour toute la vue
        return SingleChildScrollView(
          child: Column(
            children: [
              // En-têtes des équipes et formations
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        "${awayTeam.name}\n${awayFormation.formationName}",
                        style: GoogleFonts.blackOpsOne(
                          fontSize: 14,
                          color: awayColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      "VS",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "${homeTeam.name}\n${homeFormation.formationName}",
                        style: GoogleFonts.blackOpsOne(
                          fontSize: 14,
                          color: homeColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),

              // Terrain unique avec les deux équipes face à face
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Terrain avec les deux équipes
                    AspectRatio(
                      aspectRatio: 0.66, // 2:3 ratio pour avoir assez d'espace
                      child: _buildCombinedField(
                        homeStarters,
                        awayStarters,
                        homeFormation.formationName,
                        awayFormation.formationName,
                        homeColor,
                        awayColor,
                        context,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Remplaçants de l'équipe visiteuse (away)
              _buildSubstitutesSection(
                awayTeam.name,
                awayColor,
                awaySubstitutes,
                _createSubstitutions(awayEnrichedPlayers),
                context,
              ),

              const SizedBox(height: 16),

              // Remplaçants de l'équipe à domicile (home)
              _buildSubstitutesSection(
                homeTeam.name,
                homeColor,
                homeSubstitutes,
                _createSubstitutions(homeEnrichedPlayers),
                context,
              ),

              const SizedBox(height: 24), // Espace supplémentaire en bas
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }

  // Widget pour construire le terrain unique avec les deux équipes
  Widget _buildCombinedField(
    List<EnrichedPlayerEntry> homeStarters,
    List<EnrichedPlayerEntry> awayStarters,
    String homeFormation,
    String awayFormation,
    Color homeColor,
    Color awayColor,
    BuildContext context,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.green[800],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          // Terrain de football
          CustomPaint(size: Size.infinite, painter: SoccerFieldPainter()),

          // Joueurs de l'équipe à domicile (en bas)
          ...homeStarters.map((player) {
            final position = _calculatePlayerPosition(
              player,
              homeFormation,
              true, // isHomeTeam
            );

            return Positioned(
              left: position.$1 * MediaQuery.of(context).size.width * 0.82,
              top: position.$2 * MediaQuery.of(context).size.width * 1.25,
              child: _buildPlayerMarker(player, homeColor, context),
            );
          }),

          // Joueurs de l'équipe visiteuse (en haut)
          ...awayStarters.map((player) {
            final position = _calculatePlayerPosition(
              player,
              awayFormation,
              false, // isHomeTeam
            );

            return Positioned(
              left: position.$1 * MediaQuery.of(context).size.width * 0.82,
              top: position.$2 * MediaQuery.of(context).size.width * 1.25,
              child: _buildPlayerMarker(player, awayColor, context),
            );
          }),
        ],
      ),
    );
  }

  // Widget pour afficher un joueur sur le terrain
  Widget _buildPlayerMarker(
    EnrichedPlayerEntry player,
    Color teamColor,
    BuildContext context,
  ) {
    return GestureDetector(
      onTap: () => _showPlayerDetails(context, player, teamColor),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: teamColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Center(
              child: Text(
                player.jerseyNumber,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              _getShortName(player.displayName),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 8,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Calcule la position d'un joueur sur le terrain
  (double, double) _calculatePlayerPosition(
    EnrichedPlayerEntry player,
    String formation,
    bool isHomeTeam,
  ) {
    double x = 0.5;
    double y = 0.5;

    try {
      // Positions pour le gardien (toujours position 1)
      if (player.formationPlace == 1) {
        y =
            isHomeTeam
                ? 0.85
                : 0.15; // Gardien en bas ou en haut selon l'équipe
        return (0.5, y);
      }

      // Analyser la formation (ex: "4-4-2")
      final parts =
          formation.split('-').map((e) => int.tryParse(e) ?? 0).toList();
      if (parts.isEmpty) return (x, y);

      final defenders = parts[0];
      final midfielders = parts.length > 1 ? parts[1] : 0;
      final forwards = parts.length > 2 ? parts[2] : 0;

      int playerIndex =
          player.formationPlace -
          2; // Ajustement pour index 0 et sauter le gardien

      // Déterminer dans quelle ligne se trouve le joueur
      if (playerIndex < defenders) {
        // Ligne défensive
        y = isHomeTeam ? 0.70 : 0.30;
        x = (playerIndex + 1) / (defenders + 1);
      } else if (playerIndex < defenders + midfielders) {
        // Ligne de milieu
        y = isHomeTeam ? 0.55 : 0.45;
        x = (playerIndex - defenders + 1) / (midfielders + 1);
      } else {
        // Ligne d'attaque
        y = isHomeTeam ? 0.40 : 0.60;
        x = (playerIndex - defenders - midfielders + 1) / (forwards + 1);
      }

      // Ajuster x pour rester dans les limites avec une marge
      x = 0.1 + x * 0.8;
    } catch (e) {
      // Revenir à la position par défaut en cas d'erreur
    }

    return (x, y);
  }

  // Widget pour afficher la section des remplaçants
  Widget _buildSubstitutesSection(
    String teamName,
    Color teamColor,
    List<EnrichedPlayerEntry> substitutes,
    List<Substitution> substitutions,
    BuildContext context,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$teamName - Remplaçants",
            style: GoogleFonts.blackOpsOne(fontSize: 16, color: teamColor),
          ),
          const SizedBox(height: 8),
          // Utiliser Wrap pour les remplaçants pour gérer automatiquement les sauts de ligne
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children:
                substitutes
                    .map(
                      (player) =>
                          _buildSubstituteChip(player, teamColor, context),
                    )
                    .toList(),
          ),

          if (substitutions.isNotEmpty) ...[
            const Divider(height: 24),
            Text(
              "Changements",
              style: GoogleFonts.blackOpsOne(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Column(
              children:
                  substitutions
                      .map((sub) => _buildSubstitutionItem(sub, teamColor))
                      .toList(),
            ),
          ],
        ],
      ),
    );
  }

  // Widget pour afficher un remplaçant
  Widget _buildSubstituteChip(
    EnrichedPlayerEntry player,
    Color teamColor,
    BuildContext context,
  ) {
    final isSubbedIn = player.subbedIn;

    return GestureDetector(
      onTap: () => _showPlayerDetails(context, player, teamColor),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color:
              isSubbedIn
                  ? teamColor.withOpacity(0.2)
                  : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSubbedIn ? teamColor : Colors.grey,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 10,
              backgroundColor: isSubbedIn ? teamColor : Colors.grey,
              child: Text(
                player.jerseyNumber,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 3),
            Text(
              _getShortName(player.displayName),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: isSubbedIn ? teamColor : Colors.black87,
              ),
            ),
            // Indicateurs de cartons
            if (player.hasYellowCard)
              Container(
                margin: const EdgeInsets.only(left: 3),
                width: 6,
                height: 9,
                color: Colors.yellow,
              ),
            if (player.hasRedCard)
              Container(
                margin: const EdgeInsets.only(left: 3),
                width: 6,
                height: 9,
                color: Colors.red,
              ),
          ],
        ),
      ),
    );
  }

  // Widget pour afficher une substitution
  Widget _buildSubstitutionItem(Substitution sub, Color teamColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: teamColor,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              sub.minute,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.arrow_upward, color: Colors.green, size: 12),
          const SizedBox(width: 2),
          Text(
            "${sub.playerIn.jerseyNumber} ${_getShortName((sub.playerIn is EnrichedPlayerEntry) ? (sub.playerIn as EnrichedPlayerEntry).displayName : '')}",
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_downward, color: Colors.red, size: 12),
          const SizedBox(width: 2),
          Text(
            "${sub.playerOut.jerseyNumber} ${_getShortName((sub.playerOut is EnrichedPlayerEntry) ? (sub.playerOut as EnrichedPlayerEntry).displayName : '')}",
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // Afficher les détails d'un joueur dans une boîte de dialogue
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

  // Créer la liste des substitutions à partir des joueurs
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
    return substitutions;
  }

  // Obtenir un nom court pour l'affichage
  String _getShortName(String fullName) {
    if (fullName.isEmpty) return '';

    final parts = fullName.split(' ');
    if (parts.length <= 1) return fullName;

    final lastName = parts.last;
    if (lastName.length <= 6) {
      return lastName;
    } else {
      return lastName.substring(0, 5) + '.';
    }
  }
}

// Painter pour dessiner le terrain de football
class SoccerFieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;

    // Contour du terrain
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Ligne médiane
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      paint,
    );

    // Rond central
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.height / 12,
      paint,
    );

    // Surface de réparation haute (équipe visiteuse)
    final penaltyWidth = size.width * 0.5;
    final penaltyHeight = size.height * 0.15;
    canvas.drawRect(
      Rect.fromLTWH(
        (size.width - penaltyWidth) / 2,
        0,
        penaltyWidth,
        penaltyHeight,
      ),
      paint,
    );

    // Surface de réparation basse (équipe domicile)
    canvas.drawRect(
      Rect.fromLTWH(
        (size.width - penaltyWidth) / 2,
        size.height - penaltyHeight,
        penaltyWidth,
        penaltyHeight,
      ),
      paint,
    );

    // Point central
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      2,
      Paint()..color = Colors.white,
    );

    // Points de penalty
    canvas.drawCircle(
      Offset(size.width / 2, penaltyHeight / 2),
      2,
      Paint()..color = Colors.white,
    );

    canvas.drawCircle(
      Offset(size.width / 2, size.height - penaltyHeight / 2),
      2,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
