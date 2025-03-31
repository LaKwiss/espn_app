// espn_app/lib/widgets/match_info_section.dart
import 'package:flutter/material.dart';
import 'package:espn_app/models/score.dart';
import 'package:espn_app/models/team.dart';
import 'package:espn_app/widgets/score_display.dart';
import 'package:espn_app/widgets/time_display.dart';
import 'package:espn_app/widgets/team_logo.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // Import localizations

class MatchInfoSectionWidget extends StatelessWidget {
  final String date; // Already formatted with locale
  final String time; // Already formatted with locale
  final Team awayTeam;
  final Team homeTeam;
  final bool isFinished;
  final (Future<Score> away, Future<Score> home) scores;
  final bool showEvents;
  final VoidCallback onToggleEvents;
  final Color randomColor;

  const MatchInfoSectionWidget({
    super.key,
    required this.date,
    required this.time,
    required this.awayTeam,
    required this.homeTeam,
    required this.isFinished,
    required this.scores,
    required this.showEvents,
    required this.onToggleEvents,
    required this.randomColor,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!; // Get localizations
    final theme = Theme.of(context); // Get theme

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor, // Use theme color
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                date, // Already formatted date
                style: GoogleFonts.blackOpsOne(
                  fontSize: 24,
                  color: randomColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (isFinished) // Show toggle only if finished
                IconButton(
                  icon: Icon(
                    showEvents ? Icons.expand_less : Icons.expand_more,
                    color: randomColor,
                    size: 28,
                  ),
                  tooltip:
                      showEvents
                          ? l10n.hideEventsTooltip
                          : l10n.showEventsTooltip, // Localized tooltip
                  onPressed: onToggleEvents,
                ),
            ],
          ),
          const SizedBox(height: 16),
          // Affichage du score
          _buildScoreSection(context, l10n), // Pass context and l10n
          const SizedBox(height: 16),
          // Affichage des équipes
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    TeamLogoWidget(team: awayTeam, radius: 30),
                    const SizedBox(height: 8),
                    Text(
                      awayTeam.firstName, // API data
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.blackOpsOne(
                        fontSize: 20,
                        color: randomColor,
                      ),
                    ),
                    if (awayTeam.secondName.isNotEmpty)
                      Text(
                        awayTeam.secondName, // API data
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.blackOpsOne(
                          fontSize: 20,
                          color: theme.colorScheme.onSurface, // Use theme color
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    TeamLogoWidget(team: homeTeam, radius: 30),
                    const SizedBox(height: 8),
                    Text(
                      homeTeam.firstName, // API data
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.blackOpsOne(
                        fontSize: 20,
                        color: theme.colorScheme.onSurface, // Use theme color
                      ),
                    ),
                    if (homeTeam.secondName.isNotEmpty)
                      Text(
                        homeTeam.secondName, // API data
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.blackOpsOne(
                          fontSize: 20,
                          color: randomColor,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScoreSection(BuildContext context, AppLocalizations l10n) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child:
          isFinished
              ? FutureBuilder<(Score, Score)>(
                key: const ValueKey('finished-score'),
                future: Future.wait([
                  scores.$1,
                  scores.$2,
                ]).then((results) => (results[0], results[1])),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                      height: 60,
                      child: Center(
                        child: SizedBox(
                          width: 30,
                          height: 30,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    );
                  } else if (snapshot.hasError) {
                    return Text(l10n.errorLoadingScores); // Localized error
                  } else if (snapshot.hasData) {
                    final result = snapshot.data!;
                    return ScoreDisplay(
                      // Pass scores directly
                      homeScore: result.$1.value.toInt(),
                      awayScore: result.$2.value.toInt(),
                    );
                  }
                  return const SizedBox(height: 60);
                },
              )
              : TimeDisplay(
                time: time,
                randomColor: randomColor,
              ), // Time is already formatted
    );
  }
}
