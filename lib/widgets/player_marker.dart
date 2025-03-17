// lib/widgets/player_marker.dart
import 'package:flutter/material.dart';
import 'package:espn_app/models/formation_response.dart';

/// Widget pour représenter un joueur sur le terrain
class PlayerMarker extends StatelessWidget {
  final EnrichedPlayerEntry player;
  final Color teamColor;
  final VoidCallback? onTap;
  final bool isHomeTeam;

  const PlayerMarker({
    super.key,
    required this.player,
    required this.teamColor,
    this.onTap,
    this.isHomeTeam = true,
  });

  @override
  Widget build(BuildContext context) {
    // Calculer la position en fonction de l'équipe (domicile/extérieur)
    final double yPos = isHomeTeam ? player.y : 1 - player.y;

    return Positioned(
      left: player.x * 100, // En pourcentage de la largeur
      top: yPos * 100, // En pourcentage de la hauteur
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: teamColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 3,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Numéro du joueur
                  Center(
                    child: Text(
                      player.jerseyNumber,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  // Indicateur de carton jaune
                  if (player.hasYellowCard)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Colors.yellow,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  // Indicateur de carton rouge
                  if (player.hasRedCard)
                    Positioned(
                      top: 0,
                      right: player.hasYellowCard ? 12 : 0,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            // Nom du joueur
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                player.displayName,
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
}
