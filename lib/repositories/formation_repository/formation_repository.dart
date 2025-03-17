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
    String formationName,
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
          formationName,
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

  /// Calcule les coordonnées x, y sur le terrain basées sur formationPlace, totalPlayers et formationName
  (double, double) _calculatePositionCoordinates(
    int formationPlace,
    int totalPlayers,
    String? formationName,
  ) {
    // Normalisation des coordonnées entre 0 et 1
    // 0,0 = coin inférieur gauche, 1,1 = coin supérieur droit
    double x = 0.5;
    double y = 0.5;

    // Vérification du nombre total de joueurs et formation par défaut
    if (totalPlayers != 11 || formationName == null || formationName.isEmpty) {
      y = formationPlace / totalPlayers.toDouble();
      return (x, y);
    }

    // Gardien (toujours formationPlace = 1)
    if (formationPlace == 1) {
      return (0.5, 0.05); // Près du but
    }

    // Parser la formation (ex. "4-4-2" -> [4, 4, 2])
    final formationParts = formationName.split('-').map(int.parse).toList();
    if (formationParts.length < 2) {
      return (x, y); // Formation invalide, retour par défaut
    }

    // Calculer les seuils pour chaque ligne (défense, milieu, attaque)
    int defenders = formationParts[0]; // Nombre de défenseurs
    int midfielders = formationParts[1]; // Nombre de milieux
    int forwards =
        totalPlayers - 1 - defenders - midfielders; // Attaquants restants

    // Plages de formationPlace pour chaque ligne
    int defenseEnd = 1 + defenders; // 2 à 5 pour 4 défenseurs
    int midfieldEnd = defenseEnd + midfielders; // 6 à 9 pour 4 milieux

    // Défenseurs
    if (formationPlace > 1 && formationPlace <= defenseEnd) {
      y = 0.25; // Zone défensive
      double spacing = 0.8 / (defenders - 1); // Espacement horizontal
      x = 0.1 + (formationPlace - 2) * spacing; // Répartition égale
    }
    // Milieux
    else if (formationPlace > defenseEnd && formationPlace <= midfieldEnd) {
      y = 0.5; // Zone médiane
      double spacing = 0.7 / (midfielders - 1); // Espacement horizontal
      x = 0.15 + (formationPlace - defenseEnd - 1) * spacing;
    }
    // Attaquants
    else if (formationPlace > midfieldEnd) {
      y = 0.75; // Zone offensive
      double spacing = forwards > 1 ? 0.6 / (forwards - 1) : 0.0;
      x =
          forwards == 1
              ? 0.5 // Centré si un seul attaquant
              : 0.2 + (formationPlace - midfieldEnd - 1) * spacing;
    }

    // S'assurer que les coordonnées restent dans les limites
    x = x.clamp(0.0, 1.0);
    y = y.clamp(0.0, 1.0);
    return (x, y);
  }
}
