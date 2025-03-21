// lib/repositories/formation_repository/formation_repository.dart
import 'dart:convert';
import 'dart:developer' as dev;
import 'package:espn_app/models/formation_response.dart';
import 'package:espn_app/repositories/formation_repository/i_formation_repository.dart';
import 'package:espn_app/services/api_service.dart';
import 'package:espn_app/services/error_handler_service.dart';

class FormationRepository implements IFormationRepository {
  final ApiService _apiService;
  final ErrorHandlerService _errorHandler;

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

      final response = await _apiService.get(url);

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
        // Récupérer les détails du joueur
        final playerDetails = await _getPlayerDetails(player.athleteRef);

        final String displayName = playerDetails['displayName'] ?? 'Unknown';
        final String firstName = playerDetails['firstName'] ?? '';
        final String lastName = playerDetails['lastName'] ?? '';
        final String positionRef = playerDetails['position']?['\$ref'] ?? '';

        // Récupérer les détails de position si disponibles
        String positionName = 'Unknown';
        String positionAbbreviation = '';

        if (positionRef.isNotEmpty) {
          final positionDetails = await _getPositionDetails(positionRef);
          positionName = positionDetails['name'] ?? 'Unknown';
          positionAbbreviation = positionDetails['abbreviation'] ?? '';
        }

        // Calculer les coordonnées x, y sur le terrain basées sur formationPlace
        final (double x, double y) = _calculatePositionCoordinates(
          player.formationPlace,
          players.length,
        );

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
            x: x,
            y: y,
          ),
        );
      } catch (e) {
        dev.log(
          'Error enriching player data for player ${player.playerId}: $e',
        );

        // Ajouter quand même le joueur avec des valeurs par défaut
        enrichedPlayers.add(EnrichedPlayerEntry.fromPlayerEntry(player));
      }
    }

    return enrichedPlayers;
  }

  /// Récupère plus de détails sur un joueur spécifique
  Future<Map<String, dynamic>> _getPlayerDetails(String athleteRef) async {
    try {
      dev.log('Fetching player details from: $athleteRef');

      final response = await _apiService.get(athleteRef);

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

  /// Récupère les détails de position du joueur
  Future<Map<String, dynamic>> _getPositionDetails(String positionRef) async {
    try {
      dev.log('Fetching position details from: $positionRef');

      final response = await _apiService.get(positionRef);

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to load position details: ${response.statusCode}',
        );
      }

      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e, stack) {
      return _errorHandler.handleError<Map<String, dynamic>>(
        e,
        stack,
        'getPositionDetails',
        defaultValue: {},
      );
    }
  }

  /// Calcule les coordonnées x, y sur le terrain basées sur formationPlace
  (double, double) _calculatePositionCoordinates(
    int formationPlace,
    int totalPlayers,
  ) {
    // Cette méthode peut être améliorée pour mieux correspondre à la formation réelle
    // Pour l'instant, une implémentation simple basée sur formationPlace

    // Valeurs par défaut au centre du terrain
    double x = 0.5;
    double y = 0.5;

    // Si le joueur est un gardien (généralement formationPlace = 1)
    if (formationPlace == 1) {
      x = 0.5;
      y = 0.1; // Bas du terrain
    }
    // Défenseurs (formationPlace 2-5 généralement)
    else if (formationPlace >= 2 && formationPlace <= 5) {
      y = 0.25;
      // Répartir horizontalement
      x = 0.2 + ((formationPlace - 2) * 0.2);
    }
    // Milieux (formationPlace 6-8 généralement)
    else if (formationPlace >= 6 && formationPlace <= 8) {
      y = 0.5;
      // Répartir horizontalement
      x = 0.25 + ((formationPlace - 6) * 0.25);
    }
    // Attaquants (formationPlace 9-11 généralement)
    else if (formationPlace >= 9 && formationPlace <= 11) {
      y = 0.75;
      // Répartir horizontalement
      x = 0.25 + ((formationPlace - 9) * 0.25);
    }

    return (x, y);
  }
}
