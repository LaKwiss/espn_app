import 'package:espn_app/models/substitute_athlete.dart';
import 'package:espn_app/models/substitution.dart';
import 'package:flutter/material.dart';

class SubstitutesWidget extends StatelessWidget {
  final List<SubstituteAthlete> substitutes;
  final List<Substitution> substitutions;
  final Color teamColor;
  final String teamName;
  final Function(SubstituteAthlete)? onPlayerTap;

  const SubstitutesWidget({
    super.key,
    required this.substitutes,
    required this.substitutions,
    required this.teamColor,
    required this.teamName,
    this.onPlayerTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: Text(
            "$teamName - Remplaçants",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        // Liste des remplaçants
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children:
                substitutes
                    .map((player) => _buildSubstituteChip(player))
                    .toList(),
          ),
        ),
        // Séparateur
        if (substitutions.isNotEmpty)
          const Divider(height: 32, indent: 16, endIndent: 16),
        // Liste des substitutions effectuées
        if (substitutions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Changements",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...substitutions.map((sub) => _buildSubstitutionItem(sub)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSubstituteChip(SubstituteAthlete player) {
    return GestureDetector(
      onTap: () {
        if (onPlayerTap != null) {
          onPlayerTap!(player);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        decoration: BoxDecoration(
          color: teamColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: teamColor, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 12,
              backgroundColor: teamColor,
              child: Text(
                player.id.toString(), // Utiliser un numéro approprié ici
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              player.fullName,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: teamColor,
              ),
            ),
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
          const Icon(Icons.arrow_upward, color: Colors.green, size: 16),
          const SizedBox(width: 4),
          Text(
            "${sub.playerIn.id} ${sub.playerIn.fullName}",
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 16),
          const Icon(Icons.arrow_downward, color: Colors.red, size: 16),
          const SizedBox(width: 4),
          Text(
            "${sub.playerOutNumber} ${sub.playerOutName}",
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
