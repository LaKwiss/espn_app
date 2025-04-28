import 'package:flutter/material.dart';
import 'package:espn_app/models/formation_response.dart';
import 'package:espn_app/widgets/soccer_field.dart';
import 'package:espn_app/widgets/player_marker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class FormationVisualizer extends StatelessWidget {
  final String formation;
  final List<EnrichedPlayerEntry> players;
  final Color teamColor;
  final String teamName;
  final bool isHomeTeam;
  final Function(EnrichedPlayerEntry)? onPlayerTap;

  const FormationVisualizer({
    super.key,
    required this.formation,
    required this.players,
    required this.teamColor,
    required this.teamName,
    this.isHomeTeam = true,
    this.onPlayerTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final starters = players.where((p) => p.isStarter).toList();

    final List<int> formationNumbers =
        formation.split('-').map((s) => int.tryParse(s) ?? 0).toList();

    final goalkeeper = starters.firstWhere(
      (p) => p.formationPlace == 1,
      orElse: () => starters.first,
    );

    final fieldPlayers = starters.where((p) => p.formationPlace != 1).toList();

    fieldPlayers.sort((a, b) => a.formationPlace.compareTo(b.formationPlace));

    final List<List<EnrichedPlayerEntry>> lines = [];
    int currentIndex = 0;

    for (int count in formationNumbers) {
      if (currentIndex < fieldPlayers.length) {
        final endIndex =
            currentIndex + count > fieldPlayers.length
                ? fieldPlayers.length
                : currentIndex + count;

        final line = fieldPlayers.sublist(currentIndex, endIndex);
        lines.add(line);
        currentIndex = endIndex;
      }
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            l10n.teamFormation(teamName, formation),
            style: GoogleFonts.blackOpsOne(fontSize: 18, color: teamColor),
          ),
        ),
        SoccerField(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (isHomeTeam) _buildPlayerRow([goalkeeper]),
              ...isHomeTeam
                  ? lines.map((line) => _buildPlayerRow(line))
                  : lines.reversed.map((line) => _buildPlayerRow(line)),

              if (!isHomeTeam) _buildPlayerRow([goalkeeper]),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerRow(List<EnrichedPlayerEntry> rowPlayers) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children:
          rowPlayers
              .map(
                (player) => PlayerMarker(
                  player: player,
                  teamColor: teamColor,
                  isHomeTeam: isHomeTeam,
                  onTap:
                      onPlayerTap != null ? () => onPlayerTap!(player) : null,
                ),
              )
              .toList(),
    );
  }
}
