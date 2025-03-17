import 'dart:developer';
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

        return ListView(
          children: [
            _buildTeamFormation(
              homeFormation.formationName,
              homeTeam.name,
              homeColor,
              homeStarters,
              homeSubstitutes,
              _createSubstitutions(homeEnrichedPlayers),
              context,
              true,
            ),
            const SizedBox(height: 16),
            _buildTeamFormation(
              awayFormation.formationName,
              awayTeam.name,
              awayColor,
              awayStarters,
              awaySubstitutes,
              _createSubstitutions(awayEnrichedPlayers),
              context,
              false,
            ),
            const SizedBox(height: 32),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(child: Text('Error: $error')),
    );
  }

  Widget _buildTeamFormation(
    String formation,
    String teamName,
    Color teamColor,
    List<EnrichedPlayerEntry> starters,
    List<EnrichedPlayerEntry> substitutes,
    List<Substitution> substitutions,
    BuildContext context,
    bool isHomeTeam,
  ) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.symmetric(vertical: 8),
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
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  "$teamName - $formation",
                  style: GoogleFonts.blackOpsOne(
                    fontSize: 18,
                    color: teamColor,
                  ),
                ),
              ),
              AspectRatio(
                aspectRatio: 1.5,
                child: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green[800],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Stack(
                    children: [
                      CustomPaint(
                        size: Size.infinite,
                        painter: SoccerFieldPainter(),
                      ),
                      ...starters.map(
                        (player) => _positionPlayer(
                          player,
                          starters.length,
                          formation,
                          isHomeTeam,
                          teamColor,
                          context,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        _buildSubstitutesSection(
          substitutes,
          substitutions,
          teamColor,
          teamName,
        ),
      ],
    );
  }

  Widget _positionPlayer(
    EnrichedPlayerEntry player,
    int totalPlayers,
    String formation,
    bool isHomeTeam,
    Color teamColor,
    BuildContext context,
  ) {
    double x = 0.5, y = 0.5;

    if (player.formationPlace == 1) {
      // Goalkeeper position
      y = isHomeTeam ? 0.9 : 0.1;
    } else {
      // Calculate player position based on formation
      final parts = formation.split('-').map(int.parse).toList();
      if (parts.isNotEmpty) {
        final defenders = parts[0];
        final midfielders = parts.length > 1 ? parts[1] : 0;
        final forwards = parts.length > 2 ? parts[2] : 0;

        final defenseEnd = 1 + defenders;
        final midfieldEnd = defenseEnd + midfielders;

        if (player.formationPlace > 1 && player.formationPlace <= defenseEnd) {
          // Defenders
          y = isHomeTeam ? 0.7 : 0.3;
          x = 0.1 + ((player.formationPlace - 2) * 0.8 / (defenders - 1));
        } else if (player.formationPlace > defenseEnd &&
            player.formationPlace <= midfieldEnd) {
          // Midfielders
          y = isHomeTeam ? 0.5 : 0.5;
          x =
              0.1 +
              ((player.formationPlace - defenseEnd - 1) *
                  0.8 /
                  (midfielders - 1));
        } else {
          // Forwards
          y = isHomeTeam ? 0.2 : 0.8;
          x =
              0.1 +
              ((player.formationPlace - midfieldEnd - 1) *
                  0.8 /
                  (forwards - 1));
        }
      }
    }

    // Make sure x is within bounds
    x = x.clamp(0.1, 0.9);

    return Positioned(
      left: x * MediaQuery.of(context).size.width * 0.8,
      top: y * MediaQuery.of(context).size.width * 0.5, // Maintain aspect ratio
      child: GestureDetector(
        onTap: () => _showPlayerDetails(context, player, teamColor),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 30,
              height: 30,
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
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _getShortName(player.displayName),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubstitutesSection(
    List<EnrichedPlayerEntry> substitutes,
    List<Substitution> substitutions,
    Color teamColor,
    String teamName,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
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
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                substitutes
                    .map((player) => _buildSubstituteChip(player, teamColor))
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
            const SizedBox(height: 8),
            Column(
              children:
                  substitutions
                      .map((sub) => _buildSubstitutionRow(sub, teamColor))
                      .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubstituteChip(EnrichedPlayerEntry player, Color teamColor) {
    final isSubbedIn = player.subbedIn;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color:
            isSubbedIn
                ? teamColor.withOpacity(0.2)
                : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
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
          const SizedBox(width: 4),
          Text(
            _getShortName(player.displayName),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: isSubbedIn ? teamColor : Colors.black87,
            ),
          ),
          if (player.hasYellowCard)
            Container(
              margin: const EdgeInsets.only(left: 4),
              width: 6,
              height: 10,
              color: Colors.yellow,
            ),
          if (player.hasRedCard)
            Container(
              margin: const EdgeInsets.only(left: 4),
              width: 6,
              height: 10,
              color: Colors.red,
            ),
        ],
      ),
    );
  }

  Widget _buildSubstitutionRow(Substitution sub, Color teamColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
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
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_upward, color: Colors.green, size: 14),
          const SizedBox(width: 4),
          Text(
            "${sub.playerIn.jerseyNumber} ${sub.playerIn is EnrichedPlayerEntry ? _getShortName((sub.playerIn as EnrichedPlayerEntry).displayName) : ''}",
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_downward, color: Colors.red, size: 14),
          const SizedBox(width: 4),
          Text(
            "${sub.playerOut.jerseyNumber} ${sub.playerOut is EnrichedPlayerEntry ? _getShortName((sub.playerOut as EnrichedPlayerEntry).displayName) : ''}",
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

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

  String _getShortName(String fullName) {
    if (fullName.isEmpty) return '';
    final parts = fullName.split(' ');
    if (parts.length <= 1) return fullName;
    return parts.last.length <= 8
        ? parts.last
        : parts.last.substring(0, 6) + '...';
  }
}

class SoccerFieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;

    // Field outline
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Center line
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      paint,
    );

    // Center circle
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.height / 8,
      paint,
    );

    // Top penalty area
    final penaltyWidth = size.width * 0.5;
    final penaltyHeight = size.height * 0.2;
    canvas.drawRect(
      Rect.fromLTWH(
        (size.width - penaltyWidth) / 2,
        0,
        penaltyWidth,
        penaltyHeight,
      ),
      paint,
    );

    // Bottom penalty area
    canvas.drawRect(
      Rect.fromLTWH(
        (size.width - penaltyWidth) / 2,
        size.height - penaltyHeight,
        penaltyWidth,
        penaltyHeight,
      ),
      paint,
    );

    // Center spot
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      3,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
