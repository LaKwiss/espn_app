// espn_app/lib/widgets/formation_visualizer.dart
import 'package:flutter/material.dart';
import 'package:espn_app/models/formation_response.dart';
import 'package:espn_app/widgets/soccer_field.dart';
import 'package:espn_app/widgets/player_marker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // Import localizations

/// Widget de visualisation de formation tactique
class FormationVisualizer extends StatelessWidget {
  final String formation; // From API
  final List<EnrichedPlayerEntry> players;
  final Color teamColor;
  final String teamName; // From API or parent
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
    final l10n = AppLocalizations.of(context)!; // Get localizations

    // Filtrer pour n'avoir que les titulaires
    final starters = players.where((p) => p.isStarter).toList();

    // Analyser la formation (ex: "4-4-2") en une liste d'entiers
    final List<int> formationNumbers =
        formation.split('-').map((s) => int.tryParse(s) ?? 0).toList();

    // Trouver le gardien
    final goalkeeper = starters.firstWhere(
      (p) => p.formationPlace == 1, // Logic based on API data structure
      orElse: () => starters.first, // Fallback if specific place isn't found
    );

    // Extraire les joueurs de champ (tous sauf le gardien)
    final fieldPlayers = starters.where((p) => p.formationPlace != 1).toList();

    // Trier les joueurs par position sur le terrain
    fieldPlayers.sort((a, b) => a.formationPlace.compareTo(b.formationPlace));

    // Distribuer les joueurs en lignes selon la formation
    final List<List<EnrichedPlayerEntry>> lines = [];
    int currentIndex = 0;

    // Pour chaque nombre dans la formation (ex: 4,4,2)
    for (int count in formationNumbers) {
      if (currentIndex < fieldPlayers.length) {
        // Prendre les 'count' prochains joueurs pour cette ligne
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
        // Formation label
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            l10n.teamFormation(teamName, formation), // Use localized format
            style: GoogleFonts.blackOpsOne(fontSize: 18, color: teamColor),
          ),
        ),
        // Terrain avec joueurs
        SoccerField(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (isHomeTeam) _buildPlayerRow([goalkeeper]),
              // Déterminer l'ordre en fonction de l'équipe (domicile/extérieur)

              // Afficher les lignes dans le bon ordre
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

  // Construit une rangée de joueurs
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
