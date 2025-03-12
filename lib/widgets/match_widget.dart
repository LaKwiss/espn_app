import 'dart:math';

import 'package:espn_app/models/score.dart';
import 'package:espn_app/models/team.dart';
import 'package:espn_app/screens/match_detail_screen.dart';
import 'package:espn_app/widgets/widgets.dart';
import 'package:intl/intl.dart';
import 'package:espn_app/models/event.dart';

class MatchWidget extends StatelessWidget {
  final Event event;

  const MatchWidget({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final parts = event.name.split(" at ");
    final awayTeamName = parts.isNotEmpty ? parts.first.trim() : "Équipe A";
    final homeTeamName = parts.length > 1 ? parts.last.trim() : "Équipe B";
    final possibleColors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.yellow,
    ];

    // Generate a random color from the possible colors list
    final Random rnd = Random();
    final Color randomColor =
        possibleColors[rnd.nextInt(possibleColors.length)];

    final awayTeam = Team(
      id: event.idTeam.$1,
      name: awayTeamName,
      shortName: awayTeamName,
    );
    final homeTeam = Team(
      id: event.idTeam.$2,
      name: homeTeamName,
      shortName: homeTeamName,
    );

    // Conversion de la date (on suppose ici que event.date est au format ISO8601)
    final matchDate = DateTime.tryParse(event.date) ?? DateTime.now();

    // Pour cet exemple, on considère le match comme planifié (non live)
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) =>
                    MatchDetailScreen(event: event, randomColor: randomColor),
          ),
        );
      },
      child: _buildScheduledLayout(
        context,
        awayTeam,
        homeTeam,
        event.isFinished,
        event.score,
        matchDate,
        randomColor,
      ),
    );
  }

  Widget _buildScheduledLayout(
    BuildContext context,
    Team homeTeam,
    Team awayTeam,
    bool isFinished,
    (Future<Score> home, Future<Score> away) score,
    DateTime matchDate,
    Color randomColor,
  ) {
    final day = matchDate.day;
    final monthName = DateFormat.MMMM().format(matchDate);
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
                  SizedBox(height: 8),
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
                                  return const Center(child: Text('Erreur'));
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
                                        '-',
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
                                          color: Colors.black.withValues(
                                            alpha: 0.5,
                                          ),
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
                                    color: Colors.black.withValues(alpha: 0.5),
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
                      monthName,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.blackOpsOne(
                        height: 1.2,
                        fontSize: 16,
                        color: Colors.black.withValues(alpha: 0.5),
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
                                  homeTeam.firstName,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.blackOpsOne(
                                    fontSize: 22,
                                    height: 1.15,
                                    color: Colors.black,
                                  ),
                                ),
                                if (homeTeam.secondName.isNotEmpty)
                                  Text(
                                    homeTeam.secondName,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.blackOpsOne(
                                      fontSize: 22,
                                      height: 1.15,
                                      color: Colors.black.withValues(
                                        alpha: 0.5,
                                      ),
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
                                  awayTeam.firstName,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.blackOpsOne(
                                    fontSize: 22,
                                    height: 1.15,
                                    color: Colors.black.withValues(alpha: 0.5),
                                  ),
                                ),
                                if (awayTeam.secondName.isNotEmpty)
                                  Text(
                                    awayTeam.secondName,
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
        'https://a.espncdn.com/i/teamlogos/soccer/500/${team.id}.png',
      ),
    );
  }
}

Future<(Score, Score)> waitForScores(
  (Future<Score> home, Future<Score> away) scores,
) async {
  final results = await Future.wait([scores.$1, scores.$2]);
  return (results[0], results[1]);
}
