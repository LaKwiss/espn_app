// lib/widgets/formation_visualizer.dart
import 'package:flutter/material.dart';
import 'package:espn_app/models/formation_response.dart';
import 'package:espn_app/widgets/soccer_field.dart';
import 'package:espn_app/widgets/player_marker.dart';
import 'package:google_fonts/google_fonts.dart';

/// Widget de visualisation de formation tactique
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
    return Column(
      children: [
        // Formation label
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            "$teamName - $formation",
            style: GoogleFonts.blackOpsOne(fontSize: 18, color: teamColor),
          ),
        ),
        // Terrain avec joueurs
        SoccerField(child: _buildFormationLayout()),
      ],
    );
  }

  /// Construit la disposition des joueurs selon la formation
  Widget _buildFormationLayout() {
    // Filtrer pour n'avoir que les titulaires
    final starters = players.where((p) => p.isStarter).toList();

    // Si pas de données ou format invalide, retourner une vue vide
    if (starters.isEmpty || !_isValidFormation(formation)) {
      return const SizedBox();
    }

    // Analyser la formation (ex: "4-4-2" -> [4, 4, 2])
    final formationParts = formation.split('-').map(int.parse).toList();

    // Conserver une référence au gardien (toujours en position 1)
    final goalkeeper = starters.firstWhere(
      (p) => p.formationPlace == 1,
      orElse: () => starters.first,
    );

    // Trier les joueurs par position sur le terrain
    final fieldPlayers = List<EnrichedPlayerEntry>.from(starters);
    fieldPlayers.removeWhere(
      (p) => p.formationPlace == 1,
    ); // Enlever le gardien
    fieldPlayers.sort((a, b) => a.formationPlace.compareTo(b.formationPlace));

    // Répartir les joueurs selon les lignes de la formation
    final lines = _distributePlayersToLines(fieldPlayers, formationParts);

    // Inverser l'ordre si c'est l'équipe qui joue vers le haut
    final displayLines = isHomeTeam ? lines : lines.reversed.toList();

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Le gardien est toujours en première ou dernière position selon l'équipe
        if (!isHomeTeam) _buildPlayerRow([goalkeeper]),

        // Afficher les lignes de joueurs
        ...displayLines.map((linePlayers) => _buildPlayerRow(linePlayers)),

        // Le gardien est toujours en première ou dernière position selon l'équipe
        if (isHomeTeam) _buildPlayerRow([goalkeeper]),
      ],
    );
  }

  /// Répartit les joueurs en lignes selon la formation
  List<List<EnrichedPlayerEntry>> _distributePlayersToLines(
    List<EnrichedPlayerEntry> fieldPlayers,
    List<int> formationParts,
  ) {
    final lines = <List<EnrichedPlayerEntry>>[];
    int startIndex = 0;

    // Pour chaque partie de la formation (ex: 4-3-3), créer une ligne
    for (var i = 0; i < formationParts.length; i++) {
      final count = formationParts[i];
      if (startIndex + count <= fieldPlayers.length) {
        final line = fieldPlayers.sublist(startIndex, startIndex + count);
        lines.add(line);
        startIndex += count;
      }
    }

    return lines;
  }

  /// Construit une rangée de joueurs
  Widget _buildPlayerRow(List<EnrichedPlayerEntry> linePlayers) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children:
            linePlayers.map((player) {
              return PlayerMarker(
                player: player,
                teamColor: teamColor,
                isHomeTeam: isHomeTeam,
                onTap: onPlayerTap != null ? () => onPlayerTap!(player) : null,
              );
            }).toList(),
      ),
    );
  }

  /// Vérifie si la formation est valide
  bool _isValidFormation(String formation) {
    // Vérifier le format (ex: "4-4-2")
    final regex = RegExp(r'^\d+(-\d+)+$');
    if (!regex.hasMatch(formation)) {
      return false;
    }

    // Vérifier que le nombre total correspond à 10 joueurs de champ (+ 1 gardien)
    final parts = formation.split('-').map(int.parse);
    final sum = parts.fold<int>(0, (sum, count) => sum + count);
    return sum == 10; // 10 joueurs de champ (le gardien n'est pas compté ici)
  }
}
