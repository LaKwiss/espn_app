import 'package:espn_app/models/probability.dart';
import 'package:espn_app/models/team.dart';
import 'package:espn_app/screens/match_detail_screen.dart';
import 'package:espn_app/widgets/last_5_row.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // Import generated localizations

class PredictionSectionWidget extends StatelessWidget {
  const PredictionSectionWidget({
    super.key,
    required this.widget,
    required this.awayTeam,
    required this.homeTeam,
  });

  final MatchDetailScreen widget;
  final Team awayTeam;
  final Team homeTeam;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                l10n.pastGames,
                style: GoogleFonts.blackOpsOne(
                  fontSize: 28,
                  color: theme.colorScheme.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(width: 16),
              Icon(
                Icons.play_arrow,
                color: theme.colorScheme.onSurface,
                size: 32,
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    homeTeam.shortName,
                    style: GoogleFonts.blackOpsOne(
                      fontSize: 28,
                      color: theme.colorScheme.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Last5RowWidget(homeTeam.id),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                awayTeam.shortName,
                style: GoogleFonts.blackOpsOne(
                  fontSize: 28,
                  color: theme.colorScheme.onSurface.withAlpha(178),
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(width: 8),
              Last5RowWidget(awayTeam.id),
            ],
          ),
          const SizedBox(height: 48),

          FutureBuilder<List<Probability>>(
            future: Future.wait([
              widget.event.probability.$3, // away
              widget.event.probability.$2, // draw
              widget.event.probability.$1, // home
            ]),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(height: 32);
              } else if (snapshot.hasError) {
                return const SizedBox(height: 32);
              } else if (snapshot.hasData) {
                final probs = snapshot.data!;
                final int awayFlex = (probs[0].value * 100).round();
                final int drawFlex = (probs[1].value * 100).round();
                final int homeFlex = (probs[2].value * 100).round();
                final bool isDark =
                    Theme.of(context).brightness == Brightness.dark;
                final Color barColor = isDark ? Colors.white : Colors.black;

                return Row(
                  children: [
                    Expanded(
                      flex: awayFlex,
                      child: Column(
                        children: [
                          Container(
                            height: 32,
                            color: barColor.withValues(alpha: probs[0].value),
                          ),
                          Text(
                            l10n.probabilityAwayWinShort(
                              awayTeam.shortName,
                              probs[0].toString(),
                            ), // Short version
                            style: GoogleFonts.blackOpsOne(
                              fontSize: 12,
                              color: theme.colorScheme.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: drawFlex,
                      child: Column(
                        children: [
                          Container(
                            height: 32,
                            color: barColor.withValues(alpha: probs[1].value),
                          ),
                          Text(
                            l10n.probabilityDrawShort(
                              probs[1].toString(),
                            ), // Short version
                            style: GoogleFonts.blackOpsOne(
                              fontSize: 12,
                              color: theme.colorScheme.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: homeFlex,
                      child: Column(
                        children: [
                          Container(
                            height: 32,
                            color: barColor.withValues(alpha: probs[2].value),
                          ),
                          Text(
                            l10n.probabilityHomeWinShort(
                              homeTeam.shortName,
                              probs[2].toString(),
                            ),
                            style: GoogleFonts.blackOpsOne(
                              fontSize: 12,
                              color: theme.colorScheme.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }
              return const SizedBox();
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
