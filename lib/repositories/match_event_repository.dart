import 'dart:convert';
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

    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception(
        'Erreur lors de la récupération des événements du match: ${response.statusCode}',
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;

    // Récupérer les IDs des équipes
    final teamIds = await _fetchTeamIds(matchId, leagueId);

    // Parser les événements
    return MatchEvent.fromJsonList(json, teams: teamIds);
  }

  /// Récupère les IDs des équipes pour le match spécifié
  static Future<(String away, String home)> _fetchTeamIds(
    String matchId,
    String leagueId,
  ) async {
    final url =
        'http://sports.core.api.espn.com/v2/sports/soccer/leagues/$leagueId/events/$matchId?lang=en&region=us';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception('Erreur lors de la récupération des infos du match');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final competitions = json['competitions'] as List;

    if (competitions.isEmpty) {
      throw Exception(
        'Aucune information de compétition trouvée pour ce match',
      );
    }

    final competition = competitions[0] as Map<String, dynamic>;
    final competitors = competition['competitors'] as List;

    if (competitors.length < 2) {
      throw Exception('Nombre d\'équipes insuffisant pour ce match');
    }

    // Identifier quelle équipe est à domicile et à l'extérieur
    final homeTeam = competitors.firstWhere(
      (comp) => comp['homeAway'] == 'home',
      orElse: () => competitors[0],
    );

    final awayTeam = competitors.firstWhere(
      (comp) => comp['homeAway'] == 'away',
      orElse: () => competitors[1],
    );

    return (awayTeam['id'].toString(), homeTeam['id'].toString());
  }

  /// Récupère tous les événements d'un match en temps réel (pour le streaming live)
  static Future<List<MatchEvent>> fetchLiveMatchEvents({
    required String matchId,
    required String leagueId,
  }) async {
    // Même logique que fetchMatchEvents mais avec des paramètres supplémentaires
    // pour récupérer uniquement les événements récents ou modifier la requête
    // pour optimiser les performances en mode live
    return fetchMatchEvents(matchId: matchId, leagueId: leagueId);
  }
}
