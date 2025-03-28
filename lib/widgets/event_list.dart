// espn_app/lib/widgets/event_list.dart
import 'dart:developer' as dev;
import 'package:espn_app/models/match_event.dart';
import 'package:espn_app/models/team.dart';
import 'package:espn_app/widgets/widgets.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // Import localizations

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
    final l10n = AppLocalizations.of(context)!; // Get localizations
    final theme = Theme.of(context); // Get theme

    // Vérification si la liste est vide
    if (events.isEmpty) {
      return Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor, // Use theme color
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Icon(
                  Icons.sports_soccer_outlined,
                  size: 48,
                  color: Colors.grey[500], // Adjust color based on theme
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.noEventsRecorded, // Use localization key
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.checkBackLaterForUpdates, // Use localization key
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Trier les événements par heure de match
    final sortedEvents = _sortEventsByMatchTime(events);
    dev.log('${events.first}');
    dev.log('Displaying ${sortedEvents.length} sorted events');

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor, // Use theme color
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              l10n.matchEventsTitle, // Use localization key
              style: GoogleFonts.blackOpsOne(
                fontSize: 24,
                color: theme.colorScheme.onBackground, // Use theme color
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
                return _buildGoalEventItem(
                  context,
                  event,
                  index,
                  sortedEvents,
                  l10n,
                ); // Pass context and l10n
              }
              return EventWidget(event: event);
            },
          ),
        ],
      ),
    );
  }

  List<MatchEvent> _sortEventsByMatchTime(List<MatchEvent> events) {
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
    BuildContext context, // Add context
    MatchEvent event,
    int index,
    List<MatchEvent> allEvents,
    AppLocalizations l10n, // Add l10n
  ) {
    final theme = Theme.of(context); // Get theme

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
      String playerName = l10n.unknownPlayer; // Localized default
      if (event.shortText != null && event.shortText!.isNotEmpty) {
        final nameParts = event.shortText!.split(" ");
        if (nameParts.isNotEmpty) {
          playerName =
              nameParts.first; // Assumes first name is enough, adjust if needed
        }
      } else if (event.text.contains("(")) {
        final startIndex = event.text.indexOf("!");
        final endIndex = event.text.indexOf("(");
        if (startIndex != -1 && endIndex != -1 && startIndex < endIndex) {
          playerName = event.text.substring(startIndex + 1, endIndex).trim();
        }
      }

      final scoringTeamName =
          effectiveTeamGoal ? homeTeam.shortName : awayTeam.shortName;
      final teamScore = l10n.goalScoreUpdate(
        scoringTeamName,
        homeGoals,
        awayGoals,
      ); // Localized score update

      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green.withAlpha(26), // Use withAlpha
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.green.withAlpha(51),
          ), // Use withAlpha
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              alignment: Alignment.center,
              child: Text(
                event.time,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.green.withAlpha(51), // Use withAlpha
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
                    l10n.goalScoredBy(playerName), // Localized goal message
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    teamScore,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withAlpha(
                        178,
                      ), // Use theme color
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
        title: Text(l10n.goalAtTime(event.time)), // Localized fallback
        subtitle: Text(
          l10n.teamId(event.teamId ?? l10n.unknown),
        ), // Localized fallback
      );
    }
  }
}
