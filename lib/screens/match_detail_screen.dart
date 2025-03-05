import 'dart:async';

import 'package:espn_app/class/event.dart';
import 'package:espn_app/class/match_event.dart';
import 'package:espn_app/class/probability.dart';
import 'package:espn_app/class/score.dart';
import 'package:espn_app/class/team.dart';
import 'package:espn_app/repositories/match_event_repository.dart';
import 'package:espn_app/widgets/custom_app_bar.dart';
import 'package:espn_app/widgets/last_5_row_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

/// Paramètres nécessaires pour charger les événements d'un match.
class MatchParams {
  final String matchId;
  final String leagueId;
  final bool isFinished;

  MatchParams({
    required this.matchId,
    required this.leagueId,
    required this.isFinished,
  });
}

/// Un StreamProvider qui émet des listes de MatchEvent.
/// - Si `isFinished` est `false`, il rafraîchit toutes les 2s.
/// - Sinon, il ne charge qu'une seule fois.
final matchEventsStreamProvider = StreamProvider.autoDispose
    .family<List<MatchEvent>, MatchParams>((ref, params) {
      final controller = StreamController<List<MatchEvent>>.broadcast();
      bool isActive = true;
      Timer? timer;

      // Fonction pour charger les événements depuis l'API
      Future<void> loadEvents() async {
        try {
          final events = await MatchEventRepository.fetchMatchEvents(
            matchId: params.matchId,
            leagueId: params.leagueId,
          );
          if (isActive) {
            controller.add(events);
          }
        } catch (error, stackTrace) {
          if (isActive) {
            controller.addError(error, stackTrace);
          }
        }
      }

      // Charge une première fois immédiatement
      loadEvents();

      // Si le match n'est pas fini, on programme un refresh régulier
      if (!params.isFinished) {
        timer = Timer.periodic(const Duration(seconds: 2), (_) {
          loadEvents();
        });
      }

      // Lorsque personne n'écoute plus ce provider, on arrête tout
      ref.onDispose(() {
        isActive = false;
        timer?.cancel();
        controller.close();
      });

      return controller.stream;
    });

class MatchDetailScreen extends ConsumerStatefulWidget {
  static const route = '/match-detail';

  final Event event;
  final Color randomColor;

  const MatchDetailScreen({
    super.key,
    required this.event,
    required this.randomColor,
  });

  @override
  ConsumerState<MatchDetailScreen> createState() => _MatchDetailScreenState();
}

class _MatchDetailScreenState extends ConsumerState<MatchDetailScreen> {
  bool _showEvents = false;
  String _leagueId = '';

  // Pour garder une trace des équipes
  late Team _homeTeam;
  late Team _awayTeam;

  String _leagueName = '';

  @override
  void initState() {
    super.initState();

    // Extraire l'ID de la ligue à partir de l'URL
    _leagueId = _extractLeagueId(widget.event.league);

    // Initialiser les équipes
    _initializeTeams();

    _leagueName = _getLeagueNameById(_leagueId);

    // Initialiser les scores à partir des données si match terminé
    if (widget.event.isFinished) {
      _initializeScores();
    }
  }

  void _initializeTeams() {
    final parts = widget.event.name.split(" at ");
    final awayTeamName = parts.isNotEmpty ? parts.first.trim() : "Away Team";
    final homeTeamName = parts.length > 1 ? parts.last.trim() : "Home Team";

    final awayTeamShortName = widget.event.teamsShortName.$1;
    final homeTeamShortName = widget.event.teamsShortName.$2;

    _awayTeam = Team(
      id: widget.event.idTeam.$2,
      name: awayTeamName,
      shortName: awayTeamShortName,
    );

    _homeTeam = Team(
      id: widget.event.idTeam.$1,
      name: homeTeamName,
      shortName: homeTeamShortName,
    );
  }

  Future<void> _initializeScores() async {
    try {
      // Pour un match terminé, on récupère les scores via un Future
      await Future.wait([widget.event.score.$1, widget.event.score.$2]);
      // Les scores seront affichés dans le FutureBuilder du score terminé.
    } catch (e) {
      debugPrint('Erreur lors de l\'initialisation des scores: $e');
    }
  }

  String _extractLeagueId(String leagueUrl) {
    final uriParts = leagueUrl.split('/');
    for (int i = 0; i < uriParts.length; i++) {
      if (uriParts[i] == 'leagues' && i + 1 < uriParts.length) {
        String leagueWithParams = uriParts[i + 1];
        return leagueWithParams.split('?').first;
      }
    }
    return 'uefa.champions'; // Valeur par défaut
  }

  @override
  Widget build(BuildContext context) {
    final matchDate = DateTime.tryParse(widget.event.date) ?? DateTime.now();
    final formattedDate = DateFormat('dd MMMM').format(matchDate);
    final formattedTime = DateFormat('HH:mm').format(matchDate);

    // Récupération du flux des événements (Approche A)
    final eventsStream = ref.read(
      matchEventsStreamProvider(
        MatchParams(
          matchId: widget.event.id,
          leagueId: _leagueId,
          isFinished: widget.event.isFinished,
        ),
      ).stream,
    );

    return Scaffold(
      body: Container(
        color: widget.randomColor,
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: CustomAppBar(
                  url: _getLeagueLogoUrl(_leagueName),
                  backgroundColor: widget.randomColor,
                  iconOrientation: 3,
                  onArrowButtonPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ),
              SliverToBoxAdapter(child: _buildHeaderSection(widget.event)),
              if (!widget.event.isFinished)
                SliverToBoxAdapter(
                  child: _buildPredictionSection(_awayTeam, _homeTeam),
                ),
              if (widget.event.isFinished)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'TERMINÉ',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.blackOpsOne(
                        fontSize: 32,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              SliverToBoxAdapter(
                child: _buildMatchInfoSection(
                  formattedDate,
                  formattedTime,
                  _awayTeam,
                  _homeTeam,
                  widget.event.isFinished,
                  widget.event.score,
                  eventsStream, // On passe le flux ici
                ),
              ),
              if (_showEvents || !widget.event.isFinished)
                _buildEventsList(eventsStream), // On passe le flux ici
              if (!widget.event.isFinished)
                SliverToBoxAdapter(child: _buildCallToActionSection(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPredictionSection(Team awayTeam, Team homeTeam) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section "Past Games"
          Row(
            children: [
              Text(
                'Past Games',
                style: GoogleFonts.blackOpsOne(
                  fontSize: 28,
                  color: Colors.black,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(width: 16),
              const Icon(Icons.play_arrow, color: Colors.black, size: 32),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    homeTeam.shortName,
                    style: GoogleFonts.blackOpsOne(
                      fontSize: 28,
                      color: Colors.black,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Last5RowWidget(homeTeam.id),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Section "Away Team Rating"
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                awayTeam.shortName,
                style: GoogleFonts.blackOpsOne(
                  fontSize: 28,
                  color: Colors.black.withValues(alpha: 178),
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(width: 8),
              Last5RowWidget(awayTeam.id),
            ],
          ),
          const SizedBox(height: 48),
          // Section Probabilités (affichage en texte)
          FutureBuilder<List<Probability>>(
            future: Future.wait([
              widget.event.probability.$3,
              widget.event.probability.$2,
              widget.event.probability.$1,
            ]),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              } else if (snapshot.hasError) {
                return Text(
                  'Error loading probabilities',
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.blackOpsOne(fontSize: 24),
                );
              } else if (snapshot.hasData) {
                final probs = snapshot.data!;
                final awayPerc = (probs[0].value * 100).toStringAsFixed(0);
                final drawPerc = (probs[1].value * 100).toStringAsFixed(0);
                final homePerc = (probs[2].value * 100).toStringAsFixed(0);
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$awayPerc% ${awayTeam.shortName}',
                      style: GoogleFonts.blackOpsOne(
                        fontSize: 24,
                        color: Colors.black.withValues(alpha: 255),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '$drawPerc% DRAW',
                      style: GoogleFonts.blackOpsOne(
                        fontSize: 24,
                        color: Colors.black.withValues(alpha: 255),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '$homePerc% ${homeTeam.shortName}',
                      style: GoogleFonts.blackOpsOne(
                        fontSize: 24,
                        color: Colors.black.withValues(alpha: 255),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                );
              }
              return const SizedBox();
            },
          ),
          const SizedBox(height: 16),
          // Section Probabilités (représentation visuelle)
          FutureBuilder<List<Probability>>(
            future: Future.wait([
              widget.event.probability.$3,
              widget.event.probability.$2,
              widget.event.probability.$1,
            ]),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(height: 32);
              } else if (snapshot.hasError) {
                return Text(
                  'Error loading probabilities',
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.blackOpsOne(fontSize: 24),
                );
              } else if (snapshot.hasData) {
                final probs = snapshot.data!;
                final int awayFlex = (probs[0].value * 100).round();
                final int drawFlex = (probs[1].value * 100).round();
                final int homeFlex = (probs[2].value * 100).round();
                return Row(
                  children: [
                    Expanded(
                      flex: awayFlex,
                      child: Column(
                        children: [
                          Container(
                            height: 32,
                            color: Colors.black.withValues(
                              alpha: probs[0].value,
                            ),
                          ),
                          Text(
                            '${awayTeam.shortName} $awayFlex%',
                            style: GoogleFonts.blackOpsOne(
                              fontSize: 12,
                              color: Colors.black,
                            ),
                            overflow: TextOverflow.ellipsis,
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
                            color: Colors.black.withValues(
                              alpha: probs[1].value,
                            ),
                          ),
                          Text(
                            'DRAW $drawFlex%',
                            style: GoogleFonts.blackOpsOne(
                              fontSize: 12,
                              color: Colors.black,
                            ),
                            overflow: TextOverflow.ellipsis,
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
                            color: Colors.black.withValues(
                              alpha: probs[2].value,
                            ),
                          ),
                          Text(
                            '${homeTeam.shortName} $homeFlex%',
                            style: GoogleFonts.blackOpsOne(
                              fontSize: 12,
                              color: Colors.black,
                            ),
                            overflow: TextOverflow.ellipsis,
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

  Widget _buildMatchInfoSection(
    String date,
    String time,
    Team awayTeam,
    Team homeTeam,
    bool isFinished,
    (Future<Score> away, Future<Score> home) scores,
    Stream<List<MatchEvent>> eventsStream,
  ) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Date avec bouton d'expansion
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                date,
                style: GoogleFonts.blackOpsOne(
                  fontSize: 24,
                  color: const Color(0xFF5A7DF3),
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (isFinished)
                IconButton(
                  icon: Icon(
                    _showEvents ? Icons.expand_less : Icons.expand_more,
                    color: const Color(0xFF5A7DF3),
                    size: 28,
                  ),
                  onPressed: () {
                    setState(() {
                      _showEvents = !_showEvents;
                    });
                  },
                ),
            ],
          ),
          const SizedBox(height: 16),
          // Affichage du score
          AnimatedSwitcher(
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
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const SizedBox(
                            height: 60,
                            child: Center(
                              child: SizedBox(
                                width: 30,
                                height: 30,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                          );
                        } else if (snapshot.hasError) {
                          return const Text('Error loading scores');
                        } else if (snapshot.hasData) {
                          final result = snapshot.data!;
                          return _buildScoreDisplay(
                            result.$1.value.toInt(),
                            result.$2.value.toInt(),
                          );
                        }
                        return const SizedBox(height: 60);
                      },
                    )
                    : StreamBuilder<List<MatchEvent>>(
                      key: const ValueKey('live-score'),
                      stream: eventsStream,
                      builder: (context, snapshot) {
                        if (snapshot.hasError || !snapshot.hasData) {
                          // Pas encore de data ? On affiche l'heure prévue
                          return _buildTimeDisplay(time);
                        }
                        final events = snapshot.data!;
                        int homeGoals = 0;
                        int awayGoals = 0;
                        for (final event in events) {
                          if (event.type == MatchEventType.goal) {
                            if (event.teamId == _homeTeam.id.toString()) {
                              homeGoals++;
                            } else {
                              awayGoals++;
                            }
                          }
                        }
                        return _buildScoreDisplay(homeGoals, awayGoals);
                      },
                    ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.transparent,
                      backgroundImage: NetworkImage(
                        'https://a.espncdn.com/i/teamlogos/soccer/500/${awayTeam.id}.png',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      awayTeam.firstName,
                      style: GoogleFonts.blackOpsOne(
                        fontSize: 20,
                        color: const Color(0xFF5A7DF3),
                      ),
                    ),
                    if (awayTeam.secondName.isNotEmpty)
                      Text(
                        awayTeam.secondName,
                        style: GoogleFonts.blackOpsOne(
                          fontSize: 20,
                          color: Colors.black,
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.transparent,
                      backgroundImage: NetworkImage(
                        'https://a.espncdn.com/i/teamlogos/soccer/500/${homeTeam.id}.png',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      homeTeam.firstName,
                      style: GoogleFonts.blackOpsOne(
                        fontSize: 20,
                        color: Colors.black,
                      ),
                    ),
                    if (homeTeam.secondName.isNotEmpty)
                      Text(
                        homeTeam.secondName,
                        style: GoogleFonts.blackOpsOne(
                          fontSize: 20,
                          color: const Color(0xFF5A7DF3),
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

  Widget _buildTimeDisplay(String time) {
    final timeParts = time.split(':');
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '${timeParts[0]}:',
          style: GoogleFonts.blackOpsOne(fontSize: 60, color: Colors.black),
        ),
        Text(
          timeParts[1],
          style: GoogleFonts.blackOpsOne(
            fontSize: 60,
            color: const Color(0xFF5A7DF3),
          ),
        ),
      ],
    );
  }

  Widget _buildScoreDisplay(int homeScore, int awayScore) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '$homeScore:',
          style: GoogleFonts.blackOpsOne(
            fontSize: 60,
            color: const Color(0xFF5A7DF3),
          ),
        ),
        Text(
          '$awayScore',
          style: GoogleFonts.blackOpsOne(fontSize: 60, color: Colors.black),
        ),
      ],
    );
  }

  Widget _buildCallToActionSection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      color: const Color(0xFFF55E42),
      child: Text(
        'CHOOSE THE WINNER',
        textAlign: TextAlign.center,
        style: GoogleFonts.blackOpsOne(fontSize: 32, color: Colors.black),
      ),
    );
  }

  Widget _buildHeaderSection(Event event) {
    final parts = event.name.split(" at ");
    final awayTeamName = parts.isNotEmpty ? parts.first.trim() : "Away Team";
    final homeTeamName = parts.length > 1 ? parts.last.trim() : "Home Team";

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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: RichText(
        text: TextSpan(
          style: GoogleFonts.blackOpsOne(
            fontSize: 44,
            color: Colors.black,
            height: 1.1,
          ),
          children: [
            TextSpan(text: '${awayTeam.name}\n'),
            TextSpan(
              text: 'AT',
              style: GoogleFonts.blackOpsOne(
                fontSize: 44,
                color: Colors.white.withValues(alpha: 178),
              ),
            ),
            TextSpan(text: '\n${homeTeam.name}\n'),
            TextSpan(
              text: 'FIRST LEG',
              style: GoogleFonts.blackOpsOne(
                fontSize: 44,
                color: Colors.white.withValues(alpha: 178),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventsList(Stream<List<MatchEvent>> eventsStream) {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: StreamBuilder<List<MatchEvent>>(
          stream: eventsStream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text('Erreur lors du chargement des événements'),
                ),
              );
            }
            if (!snapshot.hasData) {
              return Center(
                child: Text(
                  'Le match n\'a pas encore commencé',
                  style: TextStyle(fontSize: 16),
                ),
              );
            }
            final events = snapshot.data!;
            if (events.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('Aucun événement trouvé pour ce match'),
                ),
              );
            }

            // Tri par "logique de match"
            int calculateMatchTimeWeight(String timeString) {
              if (timeString.contains("First Half ends") ||
                  timeString == "45'") {
                return 4500;
              }
              if (timeString.contains("Second Half begins") ||
                  timeString.contains("start")) {
                return 4501;
              }
              if (timeString.contains("Half-time") ||
                  timeString.contains("HT")) {
                return 4550;
              }
              if (timeString.contains("Full Time") ||
                  timeString.contains("FT")) {
                return 9900;
              }

              bool isSecondHalf = false;
              int minute = 0;
              int additionalTime = 0;

              if (timeString.contains("+")) {
                final parts = timeString.split("+");
                String minuteStr = parts[0].replaceAll(RegExp(r'[^\d]'), '');
                minute = int.tryParse(minuteStr) ?? 0;
                if (parts.length > 1) {
                  String extraTimeStr = parts[1].replaceAll(
                    RegExp(r'[^\d]'),
                    '',
                  );
                  additionalTime = int.tryParse(extraTimeStr) ?? 0;
                }
                if (minute == 45) {
                  isSecondHalf = false;
                } else if (minute == 90) {
                  isSecondHalf = true;
                }
              } else {
                String minuteStr = timeString.replaceAll(RegExp(r'[^\d]'), '');
                minute = int.tryParse(minuteStr) ?? 0;
                isSecondHalf = minute > 45;
              }

              if (isSecondHalf) {
                return 5000 + (minute * 100) + additionalTime;
              } else {
                return (minute * 100) + additionalTime;
              }
            }

            final sortedEvents = List<MatchEvent>.from(events)..sort((a, b) {
              int weightA = calculateMatchTimeWeight(a.time);
              int weightB = calculateMatchTimeWeight(b.time);
              return weightA.compareTo(weightB);
            });

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    'MATCHS EVENTS',
                    style: GoogleFonts.blackOpsOne(
                      fontSize: 24,
                      color: Colors.black,
                    ),
                  ),
                ),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: sortedEvents.length,
                  itemBuilder: (context, index) {
                    final event = sortedEvents[index];
                    if (event.type == MatchEventType.goal) {
                      return _buildGoalEventItem(event, index, sortedEvents);
                    }
                    return _buildEventItem(event);
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildGoalEventItem(
    MatchEvent event,
    int index,
    List<MatchEvent> allEvents,
  ) {
    final isHomeTeamGoal = event.teamId == _homeTeam.id.toString();
    int homeGoals = 0;
    int awayGoals = 0;
    for (int i = 0; i <= index; i++) {
      final currentEvent = allEvents[i];
      if (currentEvent.type == MatchEventType.goal) {
        if (currentEvent.teamId == _homeTeam.id.toString()) {
          homeGoals++;
        } else {
          awayGoals++;
        }
      }
    }
    String playerName = "Joueur";
    if (event.shortText != null && event.shortText!.isNotEmpty) {
      final nameParts = event.shortText!.split(" ");
      if (nameParts.isNotEmpty) {
        playerName = nameParts.first;
      }
    } else if (event.text.contains("(")) {
      final startIndex = event.text.indexOf("!");
      final endIndex = event.text.indexOf("(");
      if (startIndex != -1 && endIndex != -1 && startIndex < endIndex) {
        playerName = event.text.substring(startIndex + 1, endIndex).trim();
      }
    }
    final teamScore =
        isHomeTeamGoal
            ? '$homeGoals-$awayGoals pour ${_homeTeam.shortName}'
            : '$homeGoals-$awayGoals pour ${_awayTeam.shortName}';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 26),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.withValues(alpha: 51)),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            alignment: Alignment.center,
            child: Text(
              event.time,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.green,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 51),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.sports_soccer,
              color: Colors.green,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BUT! $playerName a marqué',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  teamScore,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black.withValues(alpha: 178),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Obtenir le nom complet de la ligue à partir de son ID
  String _getLeagueNameById(String leagueId) {
    switch (leagueId) {
      case 'ger.1':
        return 'Bundesliga';
      case 'esp.1':
        return 'LALIGA';
      case 'fra.1':
        return 'French Ligue 1';
      case 'eng.1':
        return 'Premier League';
      case 'ita.1':
        return 'Italian Serie A';
      case 'uefa.europa':
        return 'UEFA Europa League';
      case 'uefa.champions':
        return 'Champions League';
      default:
        return 'Champions League';
    }
  }

  // Obtenir l'URL du logo de la ligue
  String _getLeagueLogoUrl(String leagueName) {
    switch (leagueName) {
      case 'Bundesliga':
        return 'https://a.espncdn.com/i/leaguelogos/soccer/500/10.png';
      case 'LALIGA':
        return 'https://a.espncdn.com/i/leaguelogos/soccer/500/15.png';
      case 'French Ligue 1':
        return 'https://a.espncdn.com/i/leaguelogos/soccer/500/9.png';
      case 'Premier League':
        return 'https://a.espncdn.com/i/leaguelogos/soccer/500/23.png';
      case 'Italian Serie A':
        return 'https://a.espncdn.com/i/leaguelogos/soccer/500/12.png';
      case 'UEFA Europa League':
        return 'https://a.espncdn.com/i/leaguelogos/soccer/500/2310.png';
      case 'Champions League':
        return 'https://a.espncdn.com/i/leaguelogos/soccer/500/2.png';
      default:
        return 'https://a.espncdn.com/i/leaguelogos/soccer/500/2.png';
    }
  }

  Widget _buildEventItem(MatchEvent event) {
    IconData icon;
    Color color;

    switch (event.type) {
      case MatchEventType.yellowCard:
        icon = Icons.square;
        color = Colors.amber;
        break;
      case MatchEventType.redCard:
        icon = Icons.square;
        color = Colors.red;
        break;
      case MatchEventType.substitution:
        icon = Icons.swap_horiz;
        color = Colors.blue;
        break;
      case MatchEventType.foul:
        icon = Icons.not_interested;
        color = Colors.orange;
        break;
      case MatchEventType.kickoff:
        icon = Icons.sports_soccer;
        color = Colors.grey;
        break;
      case MatchEventType.freeKick:
        icon = Icons.sports_soccer;
        color = Colors.deepPurple;
        break;
      case MatchEventType.throwIn:
        icon = Icons.pan_tool;
        color = Colors.brown;
        break;
      case MatchEventType.shotOffTarget:
        icon = Icons.sports_soccer;
        color = Colors.grey;
        break;
      case MatchEventType.shotBlocked:
        icon = Icons.block;
        color = Colors.orange;
        break;
      default:
        icon = Icons.sports;
        color = Colors.grey;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 50,
            alignment: Alignment.center,
            child: Text(
              event.time,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 51),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              event.shortText ?? event.text,
              style: const TextStyle(fontSize: 14),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
