import 'dart:convert';
import 'dart:developer' as dev;
import 'package:espn_app/repositories/match_event_repository/i_match_event_repository.dart';
import 'package:espn_app/services/api_service.dart';
import 'package:espn_app/services/error_handler_service.dart';
import 'package:espn_app/models/match_event.dart';

class MatchEventRepository implements IMatchEventRepository {
  final ApiService _apiService;
  final ErrorHandlerService _errorHandler;

  // Cache durations for different scenarios
  static const Duration _liveMatchCacheDuration = Duration(
    seconds: 30,
  ); // Short cache for live data
  static const Duration _finishedMatchCacheDuration = Duration(
    days: 7,
  ); // Long cache for finished matches
  static const Duration _teamIdsCacheDuration = Duration(
    hours: 6,
  ); // Team IDs don't change for a match

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
      // First check if the match is currently live to determine cache duration
      final bool isLive = await _isMatchLive(matchId, leagueId);

      // Use different cache durations based on whether the match is live
      final cacheDuration =
          isLive ? _liveMatchCacheDuration : _finishedMatchCacheDuration;

      final response = await _apiService.get(
        url,
        useCache: true,
        cacheDuration: cacheDuration,
      );

      if (response.statusCode != 200) {
        dev.log(
          'Error response: ${response.statusCode}, body: ${response.body}',
        );
        dev.log('Non-200 response');
        return Future.value([]);
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      dev.log('Received match events data of length: ${response.body.length}');

      // Check if items exist in the response
      if (!json.containsKey('items') || json['items'] == null) {
        dev.log('No items found in response, using mock data');
        return Future.value([]);
      }

      final items = json['items'] as List?;
      if (items == null || items.isEmpty) {
        dev.log('Items list is empty or null, using mock data');
        return Future.value([]);
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
          return Future.value([]);
        }

        return events;
      } catch (e, stack) {
        return _errorHandler.handleError<List<MatchEvent>>(
          e,
          stack,
          'parsing events',
          defaultValue: [],
        );
      }
    } catch (e, stack) {
      return _errorHandler.handleError<List<MatchEvent>>(
        e,
        stack,
        'fetchMatchEvents',
        defaultValue: [],
      );
    }
  }

  @override
  Future<List<MatchEvent>> fetchLiveMatchEvents({
    required String matchId,
    required String leagueId,
  }) async {
    // For live events, use a very short cache duration or no cache
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
      // Team IDs for a match don't change, so we can cache them
      final response = await _apiService.get(
        url,
        cacheDuration: _teamIdsCacheDuration,
      );

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

  // Helper method to check if a match is currently live
  Future<bool> _isMatchLive(String matchId, String leagueId) async {
    try {
      final url =
          'http://sports.core.api.espn.com/v2/sports/soccer/leagues/$leagueId/events/$matchId?lang=en&region=us';

      // Use a very short cache duration for this check
      final response = await _apiService.get(
        url,
        cacheDuration: const Duration(seconds: 30),
      );

      if (response.statusCode != 200) {
        return false; // Assume not live if there's an error
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;

      // Check if competitions exist
      if (!json.containsKey('competitions') ||
          json['competitions'] == null ||
          (json['competitions'] as List).isEmpty) {
        return false;
      }

      final competitions = json['competitions'] as List;
      final competition = competitions[0] as Map<String, dynamic>;

      // Check status to determine if match is live
      if (competition.containsKey('status') &&
          competition['status'] != null &&
          competition['status'].containsKey('type') &&
          competition['status']['type'] != null) {
        final statusType = competition['status']['type'];

        // Check if status is 'in_progress' or similar
        if (statusType.containsKey('state') &&
            statusType['state'] is String &&
            statusType['state'] == 'in') {
          return true;
        }

        // Or check if liveAvailable flag is true
        if (competition.containsKey('liveAvailable') &&
            competition['liveAvailable'] == true) {
          return true;
        }
      }

      return false; // Default to not live
    } catch (e) {
      dev.log('Error checking if match is live: $e');
      return false; // Assume not live if there's an error
    }
  }
}
