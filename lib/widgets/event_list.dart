import 'dart:developer' as dev;
import 'package:espn_app/models/match_event.dart';
import 'package:espn_app/models/team.dart';
import 'package:espn_app/widgets/widgets.dart';

class EventsListWidget extends StatelessWidget {
  final List<MatchEvent> events;
  final Team homeTeam;
  final Team awayTeam;

  const EventsListWidget({
    super.key,
    required this.events,
    required this.homeTeam,
    required this.awayTeam,
  });

  @override
  Widget build(BuildContext context) {
    // Version simplifiée sans StreamBuilder
    if (events.isEmpty) {
      return Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const Icon(
                  Icons.sports_soccer_outlined,
                  size: 48,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Aucun événement enregistré pour ce match',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Revenez plus tard pour voir les mises à jour',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Trier les événements par heure de match
    final sortedEvents = _sortEventsByMatchTime(events);
    dev.log('Affichage de ${sortedEvents.length} événements triés');

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              'ÉVÉNEMENTS DU MATCH',
              style: GoogleFonts.blackOpsOne(fontSize: 24, color: Colors.black),
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
      ),
    );
  }

  // Méthodes de tri et d'affichage (inchangées)
  List<MatchEvent> _sortEventsByMatchTime(List<MatchEvent> events) {
    // Même implémentation que dans ton code original
    try {
      final sortedEvents = List<MatchEvent>.from(events)..sort((a, b) {
        int weightA = _calculateMatchTimeWeight(a.time);
        int weightB = _calculateMatchTimeWeight(b.time);
        return weightA.compareTo(weightB);
      });
      return sortedEvents;
    } catch (e) {
      dev.log('Error sorting events: $e');
      return events; // Return unsorted if sort fails
    }
  }

  int _calculateMatchTimeWeight(String timeString) {
    // Même implémentation que dans ton code original
    // ...
    // (Code repris de ta version originale)

    // First check for specific strings
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

    // Then handle regular minute formats
    try {
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
    } catch (e) {
      dev.log('Error calculating match time weight: $e');
      return 0; // Default weight if parsing fails
    }
  }

  Widget _buildGoalEventItem(
    MatchEvent event,
    int index,
    List<MatchEvent> allEvents,
  ) {
    // Même implémentation que dans ton code original
    // ...
    // (Code repris de ta version originale)

    try {
      // Compare with String or int based on what's available
      final homeTeamId = homeTeam.id.toString();
      final awayTeamId = awayTeam.id.toString();

      // Check if the event's teamId matches either home or away team
      final isHomeTeamGoal = event.teamId == homeTeamId;
      final isAwayTeamGoal = event.teamId == awayTeamId;

      // If we can't determine the team, default to home team
      final effectiveTeamGoal = isHomeTeamGoal || !isAwayTeamGoal;

      int homeGoals = 0;
      int awayGoals = 0;

      // Calculate score after this goal
      for (int i = 0; i <= index; i++) {
        final currentEvent = allEvents[i];
        if (currentEvent.type == MatchEventType.goal) {
          final isCurrentHomeGoal = currentEvent.teamId == homeTeamId;
          final isCurrentAwayGoal = currentEvent.teamId == awayTeamId;

          if (isCurrentHomeGoal || !isCurrentAwayGoal) {
            homeGoals++;
          } else {
            awayGoals++;
          }
        }
      }

      // Extract player name from event text
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
          effectiveTeamGoal
              ? '$homeGoals-$awayGoals pour ${homeTeam.shortName}'
              : '$homeGoals-$awayGoals pour ${awayTeam.shortName}';

      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
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
                color: Colors.green.withValues(alpha: 0.2),
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
                      color: Colors.black.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      dev.log('Error building goal event: $e');
      // Fallback goal event display
      return ListTile(
        leading: const Icon(Icons.sports_soccer, color: Colors.green),
        title: Text('Goal at ${event.time}'),
        subtitle: Text('Team ID: ${event.teamId ?? "unknown"}'),
      );
    }
  }
}
