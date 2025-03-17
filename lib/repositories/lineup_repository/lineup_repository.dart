// lib/repositories/lineup_repository/lineup_repository.dart
import 'dart:convert';
import 'dart:developer' as dev;
import 'package:espn_app/models/lineup.dart';
import 'package:espn_app/repositories/lineup_repository/i_lineup_repository.dart';
import 'package:espn_app/services/api_service.dart';
import 'package:espn_app/services/error_handler_service.dart';

class LineupRepository implements ILineupRepository {
  final ApiService _apiService;
  final ErrorHandlerService _errorHandler;

  LineupRepository({
    required ApiService apiService,
    required ErrorHandlerService errorHandler,
  }) : _apiService = apiService,
       _errorHandler = errorHandler;

  @override
  Future<Lineup> getTeamLineup(
    String leagueId,
    String teamId,
    String eventId,
  ) async {
    try {
      final url =
          'http://sports.core.api.espn.com/v2/sports/soccer/leagues/$leagueId/events/$eventId/competitions/$eventId/competitors/$teamId/roster?lang=en&region=us';

      dev.log('Fetching lineup from: $url');
      final response = await _apiService.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Lineup.fromJson(data);
      } else {
        throw Exception('Failed to load lineup data: ${response.statusCode}');
      }
    } catch (e, stack) {
      return _errorHandler.handleError<Lineup>(
        e,
        stack,
        'getTeamLineup',
        defaultValue: Lineup.empty(),
      );
    }
  }
}
