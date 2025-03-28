// espn_app/lib/widgets/last_matches.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // Import localizations

class LastMatches extends StatelessWidget {
  final String formString;

  const LastMatches({super.key, required this.formString});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!; // Get localizations
    final theme = Theme.of(context); // Get theme

    // Convert form string to list (e.g., "WDWLW" -> ["W", "D", "W", "L", "W"])
    final formList = formString.split('');

    // Map result codes to colors
    final colors = {'W': Colors.green, 'D': Colors.orange, 'L': Colors.red};

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.last5Matches, // Use localization key
              style: GoogleFonts.blackOpsOne(
                fontSize: 18,
                color: theme.colorScheme.onSurface, // Use theme color
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children:
                  formList.take(5).map((result) {
                    return Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colors[result] ?? Colors.grey,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(26), // Use withAlpha
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          result, // W, D, L are often kept as is for brevity
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(
                  'W',
                  l10n.legendWin,
                  Colors.green,
                  theme,
                ), // Use localized label
                const SizedBox(width: 16),
                _buildLegendItem(
                  'D',
                  l10n.legendDraw,
                  Colors.orange,
                  theme,
                ), // Use localized label
                const SizedBox(width: 16),
                _buildLegendItem(
                  'L',
                  l10n.legendLoss,
                  Colors.red,
                  theme,
                ), // Use localized label
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(
    String letter,
    String label,
    Color color,
    ThemeData theme,
  ) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 4),
        Text(
          '$letter = $label',
          style: theme.textTheme.bodySmall, // Use theme text style
        ),
      ],
    );
  }
}
