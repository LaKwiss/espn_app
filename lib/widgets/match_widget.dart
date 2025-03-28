// espn_app/lib/widgets/match_widget.dart
import 'dart:math';

import 'package:espn_app/models/score.dart';
import 'package:espn_app/models/team.dart';
import 'package:espn_app/providers/provider_factory.dart';
import 'package:espn_app/screens/match_detail_screen.dart';
import 'package:espn_app/widgets/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:espn_app/models/event.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // Import generated localizations

class MatchWidget extends ConsumerStatefulWidget {
  final Event event;

  const MatchWidget({super.key, required this.event});

  @override
  ConsumerState<MatchWidget> createState() => _MatchWidgetState();
}

class _MatchWidgetState extends ConsumerState<MatchWidget> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!; // Get localizations
    final currentLocale =
        Localizations.localeOf(context).toString(); // Get current locale

    final parts = widget.event.name.split(" at ");
    // Les noms d'équipe viennent probablement de l'API et n'ont pas besoin d'être localisés ici.
    // S'il y a des fallbacks, ils devraient être localisés.
    final awayTeamName =
        parts.isNotEmpty
            ? parts.first.trim()
            : l10n.defaultAwayTeam; // Localized fallback
    final homeTeamName =
        parts.length > 1
            ? parts.last.trim()
            : l10n.defaultHomeTeam; // Localized fallback
    final possibleColors = ref.watch(colorsProvider);

    // Generate a random color from the possible colors list
    final Random rnd = Random();
    final Color randomColor =
        possibleColors[rnd.nextInt(possibleColors.length)];

    final awayTeam = Team(
      id: widget.event.idTeam.$1,
      name: awayTeamName,
      shortName:
          awayTeamName, // Utiliser shortName venant de l'Event si disponible
    );
    final homeTeam = Team(
      id: widget.event.idTeam.$2,
      name: homeTeamName,
      shortName:
          homeTeamName, // Utiliser shortName venant de l'Event si disponible
    );

    // Conversion de la date (on suppose ici que event.date est au format ISO8601)
    final matchDate = DateTime.tryParse(widget.event.date) ?? DateTime.now();

    // Pour cet exemple, on considère le match comme planifié (non live)
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => MatchDetailScreen(
                  event: widget.event,
                  randomColor: randomColor,
                ),
          ),
        );
      },
      child: _buildScheduledLayout(
        context,
        awayTeam,
        homeTeam,
        widget.event.isFinished,
        widget.event.score,
        matchDate,
        randomColor,
        l10n,
        currentLocale,
      ),
    );
  }

  Widget _buildScheduledLayout(
    BuildContext context,
    Team awayTeam,
    Team homeTeam,
    bool isFinished,
    (Future<Score> home, Future<Score> away) score,
    DateTime matchDate,
    Color randomColor,
    AppLocalizations l10n, // Passer l10n
    String currentLocale, // Passer la locale
  ) {
    final day = matchDate.day;
    // Utiliser DateFormat avec la locale pour le nom du mois
    final monthName = DateFormat.MMMM(currentLocale).format(matchDate);
    final hourString = "${matchDate.hour.toString().padLeft(2, '0')}:";
    final minuteString = matchDate.minute.toString().padLeft(2, '0');

    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Container(
        decoration: BoxDecoration(
          color: randomColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        padding: const EdgeInsets.all(8.0),
        child: SizedBox(
          height: 104,
          child: Row(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildTeamAvatar(awayTeam),
                      const SizedBox(width: 8),
                      _buildTeamAvatar(homeTeam),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: 105,
                    height: 48,
                    child:
                        isFinished
                            ? FutureBuilder<(Score, Score)>(
                              future: waitForScores(score),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                } else if (snapshot.hasError) {
                                  return Center(
                                    child: Text(l10n.error),
                                  ); // Localized error
                                } else if (snapshot.hasData) {
                                  final scores = snapshot.data!;
                                  final homeScore = scores.$1.value;
                                  final awayScore = scores.$2.value;
                                  return Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        awayScore.toInt().toString(),
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.blackOpsOne(
                                          height: 1.25,
                                          fontSize: 42,
                                          color: Colors.black,
                                        ),
                                      ),
                                      Text(
                                        '-', // Le tiret est souvent universel
                                        style: GoogleFonts.blackOpsOne(
                                          height: 1.25,
                                          fontSize: 42,
                                          color: Colors.black,
                                        ),
                                      ),
                                      Text(
                                        homeScore.toInt().toString(),
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.blackOpsOne(
                                          height: 1.25,
                                          fontSize: 42,
                                          color: Colors.black.withAlpha(
                                            128,
                                          ), // Use withAlpha
                                        ),
                                      ),
                                    ],
                                  );
                                }
                                return const SizedBox();
                              },
                            )
                            : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  hourString,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.blackOpsOne(
                                    height: 1.25,
                                    fontSize: 32,
                                    color: Colors.black,
                                  ),
                                ),
                                Text(
                                  minuteString,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.blackOpsOne(
                                    height: 1.25,
                                    fontSize: 32,
                                    color: Colors.black.withAlpha(
                                      128,
                                    ), // Use withAlpha
                                  ),
                                ),
                              ],
                            ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              // Colonne de droite : date et noms des équipes
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "$day",
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.blackOpsOne(
                        height: 1.2,
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      monthName, // Nom du mois localisé
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.blackOpsOne(
                        height: 1.2,
                        fontSize: 16,
                        color: Colors.black.withAlpha(128), // Use withAlpha
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  homeTeam.firstName, // Nom de l'API
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.blackOpsOne(
                                    fontSize: 22,
                                    height: 1.15,
                                    color: Colors.black,
                                  ),
                                ),
                                if (homeTeam.secondName.isNotEmpty)
                                  Text(
                                    homeTeam.secondName, // Nom de l'API
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.blackOpsOne(
                                      fontSize: 22,
                                      height: 1.15,
                                      color: Colors.black.withAlpha(
                                        128,
                                      ), // Use withAlpha
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  awayTeam.firstName, // Nom de l'API
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.blackOpsOne(
                                    fontSize: 22,
                                    height: 1.15,
                                    color: Colors.black.withAlpha(
                                      128,
                                    ), // Use withAlpha
                                  ),
                                ),
                                if (awayTeam.secondName.isNotEmpty)
                                  Text(
                                    awayTeam.secondName, // Nom de l'API
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.blackOpsOne(
                                      fontSize: 22,
                                      height: 1.15,
                                      color: Colors.black,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Affichage de l'avatar de l'équipe avec ses initiales
  Widget _buildTeamAvatar(Team team) {
    return CircleAvatar(
      radius: 24,
      backgroundColor: Colors.transparent,
      backgroundImage: NetworkImage(
        // L'URL de l'image n'a pas besoin d'être localisée
        'https://a.espncdn.com/i/teamlogos/soccer/500/${team.id}.png',
      ),
      onBackgroundImageError: (exception, stackTrace) {
        // Fallback si l'image ne charge pas
        // Vous pourriez afficher une icône ou des initiales ici
      },
    );
  }
}

Future<(Score, Score)> waitForScores(
  (Future<Score> home, Future<Score> away) scores,
) async {
  final results = await Future.wait([scores.$1, scores.$2]);
  return (results[0], results[1]);
}
