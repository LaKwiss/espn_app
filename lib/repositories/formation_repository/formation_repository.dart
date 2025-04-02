import 'dart:convert';
import 'dart:developer' as dev;
import 'package:espn_app/models/formation_response.dart';
import 'package:espn_app/models/position.dart';
import 'package:espn_app/repositories/formation_repository/i_formation_repository.dart';
import 'package:espn_app/services/api_service.dart';
import 'package:espn_app/services/error_handler_service.dart';

class FormationRepository implements IFormationRepository {
  final ApiService _apiService;
  final ErrorHandlerService _errorHandler;

  static const Duration _formationCacheDuration = Duration(hours: 2);
  static const Duration _playerDetailsCacheDuration = Duration(hours: 12);
  static const Duration _positionCacheDuration = Duration(days: 30);

  FormationRepository({
    required ApiService apiService,
    required ErrorHandlerService errorHandler,
  }) : _apiService = apiService,
       _errorHandler = errorHandler;

  @override
  Future<FormationResponse> getTeamFormation({
    required String matchId,
    required String teamId,
    required String leagueId,
  }) async {
    try {
      final url =
          'http://sports.core.api.espn.com/v2/sports/soccer/leagues/$leagueId/events/$matchId/competitions/$matchId/competitors/$teamId/roster';

      dev.log('Fetching team formation from: $url');

      final response = await _apiService.get(
        url,
        cacheDuration: _formationCacheDuration,
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to load team formation: ${response.statusCode}',
        );
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return FormationResponse.fromJson(data);
    } catch (e, stack) {
      return _errorHandler.handleError<FormationResponse>(
        e,
        stack,
        'getTeamFormation',
        defaultValue: FormationResponse.fromJson({
          'formation': {'name': 'Unknown'},
          'entries': [],
        }),
      );
    }
  }

  @override
  Future<List<EnrichedPlayerEntry>> enrichPlayersData(
    List<PlayerEntry> players,
  ) async {
    final enrichedPlayers = <EnrichedPlayerEntry>[];

    for (var player in players) {
      try {
        final playerDetails = await _getPlayerDetails(player.athleteRef);

        final String displayName = playerDetails['displayName'] ?? 'Unknown';
        final String firstName = playerDetails['firstName'] ?? '';
        final String lastName = playerDetails['lastName'] ?? '';
        final String positionRefUrl = playerDetails['position']?['\$ref'] ?? '';

        String positionName = 'Unknown';
        String positionAbbreviation = '';

        if (positionRefUrl.isNotEmpty) {
          final uri = Uri.parse(positionRefUrl);
          final pathSegments = uri.pathSegments;
          final positionId =
              pathSegments.isNotEmpty ? int.tryParse(pathSegments.last) : null;

          if (positionId != null) {
            final positionDetails = await _getPositionDetails(positionId);
            positionName = positionDetails.name;
            positionAbbreviation = positionDetails.abbreviation;
          }
        }

        enrichedPlayers.add(
          EnrichedPlayerEntry(
            playerId: player.playerId,
            jerseyNumber: player.jerseyNumber,
            isStarter: player.isStarter,
            formationPlace: player.formationPlace,
            subbedIn: player.subbedIn,
            subbedOut: player.subbedOut,
            replacementId: player.replacementId,
            subMinute: player.subMinute,
            athleteRef: player.athleteRef,
            displayName: displayName,
            firstName: firstName,
            lastName: lastName,
            positionName: positionName,
            positionAbbreviation: positionAbbreviation,
          ),
        );
      } catch (e) {
        dev.log(
          'Error enriching player data for player ${player.playerId}: $e',
        );
        enrichedPlayers.add(EnrichedPlayerEntry.fromPlayerEntry(player));
      }
    }

    return enrichedPlayers;
  }

  Future<Map<String, dynamic>> _getPlayerDetails(String athleteRef) async {
    try {
      dev.log('Fetching player details from: $athleteRef');

      // Use cache for player details
      final response = await _apiService.get(
        athleteRef,
        cacheDuration: _playerDetailsCacheDuration,
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to load player details: ${response.statusCode}',
        );
      }

      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e, stack) {
      return _errorHandler.handleError<Map<String, dynamic>>(
        e,
        stack,
        'getPlayerDetails',
        defaultValue: {},
      );
    }
  }

  Future<Position> _getPositionDetails(int position) async {
    try {
      final positionRef =
          'http://sports.core.api.espn.com/v2/sports/soccer/leagues/ger.1/positions/$position';

      dev.log('Fetching position details from: $positionRef');

      final response = await _apiService.get(
        positionRef,
        cacheDuration: _positionCacheDuration,
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to load position details: ${response.statusCode}',
        );
      }

      return Position.fromJson(jsonDecode(response.body));
    } catch (e, stack) {
      return _errorHandler.handleError<Position>(
        e,
        stack,
        'getPositionDetails',
      );
    }
  }
}
