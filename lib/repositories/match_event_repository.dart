import 'dart:convert';
import 'dart:developer' as dev;
import 'package:http/http.dart' as http;
import 'package:espn_app/class/match_event.dart';

class MatchEventRepository {
  /// Récupère tous les événements d'un match spécifique avec l'ID de la ligue
  static Future<List<MatchEvent>> fetchMatchEvents({
    required String matchId,
    required String leagueId,
  }) async {
    final url =
        'http://sports.core.api.espn.com/v2/sports/soccer/leagues/$leagueId/events/$matchId/competitions/$matchId/plays?limit=1000';

    dev.log('Fetching match events from: $url');

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode != 200) {
        dev.log(
          'Error response: ${response.statusCode}, body: ${response.body}',
        );
        throw Exception('Failed to fetch match events: ${response.statusCode}');
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      dev.log('Received match events data of length: ${response.body.length}');

      // Check if items exist in the response
      if (!json.containsKey('items') || json['items'] == null) {
        dev.log('No items found in response');
        return [];
      }

      final items = json['items'] as List?;
      if (items == null || items.isEmpty) {
        dev.log('Items list is empty or null');
        return [];
      }

      dev.log('Found ${items.length} events in response');

      // Récupérer les IDs des équipes
      final teamIds = await _fetchTeamIds(matchId, leagueId);
      dev.log('Team IDs: ${teamIds.$1}, ${teamIds.$2}');

      // Generate mock events if list is empty (for testing)
      if (items.isEmpty) {
        dev.log('Generating mock events for testing');
        return _generateMockEvents(teamIds);
      }

      // Parser les événements
      try {
        final events = MatchEvent.fromJsonList(json, teams: teamIds);
        dev.log('Successfully parsed ${events.length} events');
        return events;
      } catch (e, stack) {
        dev.log('Error parsing events: $e');
        dev.log('Stack trace: $stack');
        // Return empty list on parse error
        return [];
      }
    } catch (e, stack) {
      dev.log('Error fetching match events: $e');
      dev.log('Stack trace: $stack');
      // For testing, we can return mock events instead of rethrowing
      // return _generateMockEvents(await _fetchTeamIds(matchId, leagueId));
      throw Exception('Failed to fetch match events: $e');
    }
  }

  /// Récupère les IDs des équipes pour le match spécifié
  static Future<(String away, String home)> _fetchTeamIds(
    String matchId,
    String leagueId,
  ) async {
    final url =
        'http://sports.core.api.espn.com/v2/sports/soccer/leagues/$leagueId/events/$matchId?lang=en&region=us';

    dev.log('Fetching team IDs from: $url');

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode != 200) {
        dev.log('Error response: ${response.statusCode}');
        throw Exception('Failed to fetch match info');
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;

      // Check if competitions exist
      if (!json.containsKey('competitions') ||
          json['competitions'] == null ||
          (json['competitions'] as List).isEmpty) {
        dev.log('No competition data found');
        return ('0', '0'); // Default IDs
      }

      final competitions = json['competitions'] as List;
      final competition = competitions[0] as Map<String, dynamic>;

      // Check if competitors exist
      if (!competition.containsKey('competitors') ||
          competition['competitors'] == null ||
          (competition['competitors'] as List).length < 2) {
        dev.log('Insufficient competitor data');
        return ('0', '0'); // Default IDs
      }

      final competitors = competition['competitors'] as List;

      // Identify home and away teams
      final homeTeam = competitors.firstWhere(
        (comp) => comp['homeAway'] == 'home',
        orElse: () => competitors[0],
      );

      final awayTeam = competitors.firstWhere(
        (comp) => comp['homeAway'] == 'away',
        orElse: () => competitors[1],
      );

      final homeId = homeTeam['id']?.toString() ?? '0';
      final awayId = awayTeam['id']?.toString() ?? '0';

      dev.log('Found team IDs - home: $homeId, away: $awayId');
      return (awayId, homeId);
    } catch (e, stack) {
      dev.log('Error fetching team IDs: $e');
      dev.log('Stack trace: $stack');
      // Return default IDs on error
      return ('0', '0');
    }
  }

  /// Récupère tous les événements d'un match en temps réel (pour le streaming live)
  static Future<List<MatchEvent>> fetchLiveMatchEvents({
    required String matchId,
    required String leagueId,
  }) async {
    // Same as fetchMatchEvents but optimized for live
    return fetchMatchEvents(matchId: matchId, leagueId: leagueId);
  }

  /// Generate mock events for testing
  static List<MatchEvent> _generateMockEvents(
    (String away, String home) teams,
  ) {
    final now = DateTime.now();

    return [
      MatchEvent(
        id: '1',
        type: MatchEventType.kickoff,
        text: 'Kickoff',
        alternateText: 'Coup d\'envoi',
        time: '1\'',
        period: MatchEventPeriod.firstHalf,
        score: (0, 0),
        teams: teams,
        isScoring: false,
        isPriority: true,
        wallClock: now.subtract(const Duration(minutes: 45)),
        participants: [],
      ),
      MatchEvent(
        id: '2',
        type: MatchEventType.goal,
        text: 'Goal! Player 1',
        alternateText: 'But! Joueur 1',
        shortText: 'Player 1 Goal',
        time: '23\'',
        period: MatchEventPeriod.firstHalf,
        score: (1, 0),
        teams: teams,
        teamId: teams.$1, // Away team scored
        isScoring: true,
        isPriority: true,
        wallClock: now.subtract(const Duration(minutes: 22)),
        participants: [],
      ),
      MatchEvent(
        id: '3',
        type: MatchEventType.yellowCard,
        text: 'Yellow Card for Player 2',
        alternateText: 'Carton jaune pour Joueur 2',
        time: '38\'',
        period: MatchEventPeriod.firstHalf,
        score: (1, 0),
        teams: teams,
        teamId: teams.$2, // Home team got card
        isScoring: false,
        isPriority: false,
        wallClock: now.subtract(const Duration(minutes: 7)),
        participants: [],
      ),
      MatchEvent(
        id: '4',
        type: MatchEventType.goal,
        text: 'Goal! Player 3',
        alternateText: 'But! Joueur 3',
        shortText: 'Player 3 Goal',
        time: '52\'',
        period: MatchEventPeriod.secondHalf,
        score: (1, 1),
        teams: teams,
        teamId: teams.$2, // Home team scored
        isScoring: true,
        isPriority: true,
        wallClock: now.subtract(const Duration(minutes: 38)),
        participants: [],
      ),
    ];
  }
}
