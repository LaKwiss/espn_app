import 'dart:developer' as dev;
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
          // Case 1: Loading state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            );
          }

          // Case 2: Error occurred
          if (snapshot.hasError) {
            dev.log('StreamBuilder error: ${snapshot.error}');
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text('Error loading match events: ${snapshot.error}'),
                  ],
                ),
              ),
            );
          }

          // Case 3: Empty events list or no data
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
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
                      'No events recorded for this match yet',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Check back once the match begins',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            );
          }

          // Case 4: We have events to display
          final events = snapshot.data!;
          dev.log('Events count: ${events.length}');

          final sortedEvents = _sortEventsByMatchTime(events);
          dev.log('Sorted events count: ${sortedEvents.length}');

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
    MatchEvent event,
    int index,
    List<MatchEvent> allEvents,
  ) {
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
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green.withOpacity(0.2)),
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
                color: Colors.green.withOpacity(0.2),
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
                      color: Colors.black.withOpacity(0.7),
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
