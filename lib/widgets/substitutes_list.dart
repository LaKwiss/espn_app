import 'package:flutter/material.dart';
import 'package:espn_app/models/formation_response.dart';
import 'package:google_fonts/google_fonts.dart';

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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
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
          _buildSubstitutesList(),
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
            _buildSubstitutionsList(),
          ],
        ],
      ),
    );
  }

  Widget _buildSubstitutesList() {
    // Using Wrap widget to automatically flow items
    return Wrap(
      spacing: 6.0,
      runSpacing: 6.0,
      children:
          substitutes.map((player) => _buildSubstituteChip(player)).toList(),
    );
  }

  Widget _buildSubstituteChip(EnrichedPlayerEntry player) {
    final isSubbedIn = player.subbedIn;

    return GestureDetector(
      onTap: onPlayerTap != null ? () => onPlayerTap!(player) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 3.0),
        decoration: BoxDecoration(
          color:
              isSubbedIn
                  ? teamColor.withOpacity(0.2)
                  : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12.0),
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
            // Indicators for cards
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

  Widget _buildSubstitutionsList() {
    return Column(
      children:
          substitutions.map((sub) => _buildSubstitutionItem(sub)).toList(),
    );
  }

  Widget _buildSubstitutionItem(Substitution sub) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
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
            "${sub.playerIn.jerseyNumber} ${_getPlayerName(sub.playerIn)}",
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
            "${sub.playerOut.jerseyNumber} ${_getPlayerName(sub.playerOut)}",
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

  String _getPlayerName(PlayerEntry player) {
    if (player is EnrichedPlayerEntry) {
      return _getShortName(player.displayName);
    }
    return '';
  }

  String _getShortName(String fullName) {
    if (fullName.isEmpty) return '';

    final parts = fullName.split(' ');
    if (parts.length <= 1) return fullName;

    final lastName = parts.last;
    if (lastName.length <= 5) {
      return lastName;
    } else {
      return lastName.substring(0, 4) + '.';
    }
  }
}
