// lib/widgets/substitutes_list.dart
import 'package:flutter/material.dart';
import 'package:espn_app/models/formation_response.dart';
import 'package:google_fonts/google_fonts.dart';

/// Widget pour afficher la liste des remplaçants
class SubstitutesList extends StatelessWidget {
  final List<EnrichedPlayerEntry> substitutes;
  final List<Substitution> substitutions;
  final Color teamColor;
  final String teamName;
  final Function(EnrichedPlayerEntry)? onPlayerTap;

  const SubstitutesList({
    super.key,
    required this.substitutes,
    required this.substitutions,
    required this.teamColor,
    required this.teamName,
    this.onPlayerTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Container(
        padding: const EdgeInsets.only(
          left: 16.0,
          top: 8.0,
          right: 16.0,
          bottom: 8.0,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.0),
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
              style: GoogleFonts.blackOpsOne(fontSize: 18, color: teamColor),
            ),
            const SizedBox(height: 12),
            // Liste des remplaçants
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children:
                  substitutes
                      .map((player) => _buildSubstituteChip(player))
                      .toList(),
            ),
            // Séparateur
            if (substitutions.isNotEmpty) const Divider(height: 32),
            // Liste des substitutions effectuées
            if (substitutions.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Changements",
                    style: GoogleFonts.blackOpsOne(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...substitutions.map((sub) => _buildSubstitutionItem(sub)),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubstituteChip(EnrichedPlayerEntry player) {
    final isSubbedIn = player.subbedIn;

    return GestureDetector(
      onTap: () {
        if (onPlayerTap != null) {
          onPlayerTap!(player);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        decoration: BoxDecoration(
          color:
              isSubbedIn
                  ? teamColor.withOpacity(0.2)
                  : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(
            color: isSubbedIn ? teamColor : Colors.grey,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 12,
              backgroundColor: isSubbedIn ? teamColor : Colors.grey,
              child: Text(
                player.jerseyNumber,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              player.displayName,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isSubbedIn ? teamColor : Colors.black87,
              ),
            ),
            // Indicateurs de cartons
            if (player.hasYellowCard)
              Container(
                margin: const EdgeInsets.only(left: 4),
                width: 8,
                height: 12,
                color: Colors.yellow,
              ),
            if (player.hasRedCard)
              Container(
                margin: const EdgeInsets.only(left: 4),
                width: 8,
                height: 12,
                color: Colors.red,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubstitutionItem(Substitution sub) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          // Indicateur minute
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: teamColor,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              sub.minute,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Flèche d'entrée
          const Icon(Icons.arrow_upward, color: Colors.green, size: 16),
          const SizedBox(width: 4),
          Text(
            "${sub.playerIn.jerseyNumber} ${sub.playerIn is EnrichedPlayerEntry ? (sub.playerIn as EnrichedPlayerEntry).displayName : ''}",
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 16),
          // Flèche de sortie
          const Icon(Icons.arrow_downward, color: Colors.red, size: 16),
          const SizedBox(width: 4),
          Text(
            "${sub.playerOut.jerseyNumber} ${sub.playerOut is EnrichedPlayerEntry ? (sub.playerOut as EnrichedPlayerEntry).displayName : ''}",
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
