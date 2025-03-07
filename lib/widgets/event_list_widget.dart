import 'package:flutter/material.dart';
import 'package:espn_app/class/match_event.dart';
import 'package:espn_app/class/team.dart';
import 'package:espn_app/widgets/event_widget.dart';
import 'package:google_fonts/google_fonts.dart';

class EventsListWidget extends StatelessWidget {
  final Stream<List<MatchEvent>> eventsStream;
  final Team homeTeam;
  final Team awayTeam;

  const EventsListWidget({
    super.key,
    required this.eventsStream,
    required this.homeTeam,
    required this.awayTeam,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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

          final sortedEvents = _sortEventsByMatchTime(events);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  'ÉVÉNEMENTS DU MATCH',
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
                  return EventWidget(event: event);
                },
              ),
            ],
          );
        },
      ),
    );
  }

  List<MatchEvent> _sortEventsByMatchTime(List<MatchEvent> events) {
    final sortedEvents = List<MatchEvent>.from(events)..sort((a, b) {
      int weightA = _calculateMatchTimeWeight(a.time);
      int weightB = _calculateMatchTimeWeight(b.time);
      return weightA.compareTo(weightB);
    });

    return sortedEvents;
  }

  int _calculateMatchTimeWeight(String timeString) {
    if (timeString.contains("First Half ends") || timeString == "45'") {
      return 4500;
    }
    if (timeString.contains("Second Half begins") ||
        timeString.contains("start")) {
      return 4501;
    }
    if (timeString.contains("Half-time") || timeString.contains("HT")) {
      return 4550;
    }
    if (timeString.contains("Full Time") || timeString.contains("FT")) {
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
        String extraTimeStr = parts[1].replaceAll(RegExp(r'[^\d]'), '');
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

  Widget _buildGoalEventItem(
    MatchEvent event,
    int index,
    List<MatchEvent> allEvents,
  ) {
    final isHomeTeamGoal = event.teamId == homeTeam.id.toString();
    int homeGoals = 0;
    int awayGoals = 0;
    for (int i = 0; i <= index; i++) {
      final currentEvent = allEvents[i];
      if (currentEvent.type == MatchEventType.goal) {
        if (currentEvent.teamId == homeTeam.id.toString()) {
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
            ? '$homeGoals-$awayGoals pour ${homeTeam.shortName}'
            : '$homeGoals-$awayGoals pour ${awayTeam.shortName}';

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
}
