import 'package:flutter/material.dart';
import 'package:espn_app/models/formation_response.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

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
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.substitutesTitle(teamName),
              style: GoogleFonts.blackOpsOne(fontSize: 18, color: teamColor),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children:
                  substitutes
                      .map((player) => _buildSubstituteChip(player, theme))
                      .toList(),
            ),
            if (substitutions.isNotEmpty) const Divider(height: 32),
            if (substitutions.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.changesTitle,
                    style: GoogleFonts.blackOpsOne(
                      fontSize: 16,
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...substitutions.map(
                    (sub) => _buildSubstitutionItem(sub, theme),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubstituteChip(EnrichedPlayerEntry player, ThemeData theme) {
    final isSubbedIn = player.subbedIn;
    final bool isDark = theme.brightness == Brightness.dark;
    final Color chipBackgroundColor =
        isSubbedIn
            ? teamColor.withValues(alpha: 0.2)
            : (isDark ? Colors.grey.shade800 : Colors.grey.shade200);
    final Color chipBorderColor = isSubbedIn ? teamColor : Colors.grey.shade400;
    final Color chipTextColor =
        isSubbedIn
            ? teamColor
            : theme.colorScheme.onSurface.withValues(alpha: 0.87);
    final Color avatarBackgroundColor =
        isSubbedIn ? teamColor : Colors.grey.shade600;
    final Color avatarTextColor = Colors.white;

    return GestureDetector(
      onTap: () {
        if (onPlayerTap != null) {
          onPlayerTap!(player);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        decoration: BoxDecoration(
          color: chipBackgroundColor,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: chipBorderColor, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 12,
              backgroundColor: avatarBackgroundColor,
              child: Text(
                player.jerseyNumber,
                style: TextStyle(
                  color: avatarTextColor,
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
                color: chipTextColor,
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

  Widget _buildSubstitutionItem(Substitution sub, ThemeData theme) {
    final Color textColor = theme.colorScheme.onSurface.withValues(alpha: 0.87);

    final String playerInName =
        sub.playerIn is EnrichedPlayerEntry
            ? (sub.playerIn as EnrichedPlayerEntry).displayName
            : 'Unknown';
    final String playerOutName =
        sub.playerOut is EnrichedPlayerEntry
            ? (sub.playerOut as EnrichedPlayerEntry).displayName
            : 'Unknown';

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
          Expanded(
            flex: 1,
            child: Text(
              "${sub.playerIn.jerseyNumber} $playerInName",
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
          ),
          const SizedBox(width: 16),
          const Icon(Icons.arrow_downward, color: Colors.red, size: 16),
          const SizedBox(width: 4),
          Expanded(
            flex: 1,
            child: Text(
              "${sub.playerOut.jerseyNumber} $playerOutName",
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
