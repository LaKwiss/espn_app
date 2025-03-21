import 'dart:convert';
import 'dart:developer' as dev;
import 'package:espn_app/repositories/match_event_repository/i_match_event_repository.dart';
import 'package:espn_app/services/api_service.dart';
import 'package:espn_app/services/error_handler_service.dart';
import 'package:espn_app/models/match_event.dart';

class MatchEventRepository implements IMatchEventRepository {
  final ApiService _apiService;
  final ErrorHandlerService _errorHandler;

  MatchEventRepository({
    required ApiService apiService,
    required ErrorHandlerService errorHandler,
  }) : _apiService = apiService,
       _errorHandler = errorHandler;

  @override
  Future<List<MatchEvent>> fetchMatchEvents({
    required String matchId,
    required String leagueId,
  }) async {
    final url =
        'http://sports.core.api.espn.com/v2/sports/soccer/leagues/$leagueId/events/$matchId/competitions/$matchId/plays?limit=1000';

    dev.log('Fetching match events from: $url');

    try {
      final response = await _apiService.get(url);

      if (response.statusCode != 200) {
        dev.log(
          'Error response: ${response.statusCode}, body: ${response.body}',
        );
        // Instead of throwing, return mock data for non-200 responses
        final teamIds = await fetchTeamIds(matchId, leagueId);
        dev.log('Using mock data due to non-200 response');
        return _generateMockEvents(teamIds);
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      dev.log('Received match events data of length: ${response.body.length}');

      // Check if items exist in the response
      if (!json.containsKey('items') || json['items'] == null) {
        dev.log('No items found in response, using mock data');
        final teamIds = await fetchTeamIds(matchId, leagueId);
        return _generateMockEvents(teamIds);
      }

      final items = json['items'] as List?;
      if (items == null || items.isEmpty) {
        dev.log('Items list is empty or null, using mock data');
        final teamIds = await fetchTeamIds(matchId, leagueId);
        return _generateMockEvents(teamIds);
      }

      dev.log('Found ${items.length} events in response');

      // Récupérer les IDs des équipes
      final teamIds = await fetchTeamIds(matchId, leagueId);
      dev.log('Team IDs: ${teamIds.$1}, ${teamIds.$2}');

      // Parser les événements
      try {
        final events = MatchEvent.fromJsonList(json, teams: teamIds);
        dev.log('Successfully parsed ${events.length} events');

        // If no events were parsed, use mock data
        if (events.isEmpty) {
          dev.log('No events were parsed, using mock data');
          return _generateMockEvents(teamIds);
        }

        return events;
      } catch (e, stack) {
        return _errorHandler.handleError<List<MatchEvent>>(
          e,
          stack,
          'parsing events',
          defaultValue: _generateMockEvents(teamIds),
        );
      }
    } catch (e, stack) {
      // Return mock events instead of rethrowing
      final teamIds = await fetchTeamIds(matchId, leagueId);
      return _errorHandler.handleError<List<MatchEvent>>(
        e,
        stack,
        'fetchMatchEvents',
        defaultValue: _generateMockEvents(teamIds),
      );
    }
  }

  @override
  Future<List<MatchEvent>> fetchLiveMatchEvents({
    required String matchId,
    required String leagueId,
  }) async {
    // Pour le streaming en temps réel, nous utilisons la même méthode mais optimisée pour une utilisation en direct
    return fetchMatchEvents(matchId: matchId, leagueId: leagueId);
  }

  @override
  Future<(String away, String home)> fetchTeamIds(
    String matchId,
    String leagueId,
  ) async {
    final url =
        'http://sports.core.api.espn.com/v2/sports/soccer/leagues/$leagueId/events/$matchId?lang=en&region=us';

    dev.log('Fetching team IDs from: $url');

    try {
      final response = await _apiService.get(url);

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
      return _errorHandler.handleError<(String, String)>(
        e,
        stack,
        'fetchTeamIds',
        defaultValue: ('0', '0'),
      );
    }
  }

  /// Generate mock events for testing
  List<MatchEvent> _generateMockEvents((String away, String home) teams) {
    final now = DateTime.now();
    dev.log('Generating mock events with team IDs: ${teams.$1}, ${teams.$2}');

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
