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
        SoccerField(
          child: Stack(
            children: [
              // Placement des joueurs
              ...players.map(
                (player) => PlayerMarker(
                  player: player,
                  teamColor: teamColor,
                  isHomeTeam: isHomeTeam,
                  onTap: () {
                    if (onPlayerTap != null) {
                      onPlayerTap!(player);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
