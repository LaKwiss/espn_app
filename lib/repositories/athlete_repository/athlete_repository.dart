import 'dart:convert';
import 'dart:developer' as dev;
import 'package:espn_app/models/athlete.dart';
import 'package:espn_app/models/club.dart';
import 'package:espn_app/models/stats.dart';
import 'package:espn_app/repositories/athlete_repository/i_athlete_repository.dart';
import 'package:espn_app/services/api_service.dart';
import 'package:espn_app/services/error_handler_service.dart';

class AthletesRepository implements IAthletesRepository {
  final ApiService _apiService;
  final ErrorHandlerService _errorHandler;

  // Athlete data doesn't change frequently, so we can cache it for a day
  static const Duration _athleteCacheDuration = Duration(days: 1);
  static const Duration _teamAthletesCacheDuration = Duration(hours: 12);

  AthletesRepository({
    required ApiService apiService,
    required ErrorHandlerService errorHandler,
  }) : _apiService = apiService,
       _errorHandler = errorHandler;

  @override
  Future<List<Athlete>> getTeamAthletes(String leagueId, String teamId) async {
    try {
      final url =
          'http://sports.core.api.espn.com/v2/sports/soccer/leagues/$leagueId/seasons/2024/teams/$teamId/athletes?limit=1000';

      dev.log('Fetching athletes from: $url');
      // Use cache with team athletes duration
      final response = await _apiService.get(
        url,
        cacheDuration: _teamAthletesCacheDuration,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<Athlete> athletes = [];

        // Vérifier si items existe et est une liste
        if (data.containsKey('items') && data['items'] is List) {
          final List<dynamic> items = data['items'];

          // Pour chaque référence d'athlète, récupérer ses données complètes
          for (var item in items) {
            if (item.containsKey('\$ref')) {
              final String athleteUrl = item['\$ref'];
              try {
                // Use cache for individual athlete data
                final athleteResponse = await _apiService.get(
                  athleteUrl,
                  cacheDuration: _athleteCacheDuration,
                );
                if (athleteResponse.statusCode == 200) {
                  final athleteData = jsonDecode(athleteResponse.body);
                  athletes.add(Athlete.fromJson(athleteData));
                }
              } catch (e) {
                dev.log('Error fetching athlete data: $e');
              }
            }
          }
        }

        return athletes;
      } else {
        throw Exception('Failed to load athletes data: ${response.statusCode}');
      }
    } catch (e, stack) {
      return _errorHandler.handleError<List<Athlete>>(
        e,
        stack,
        'getTeamAthletes',
        defaultValue: [],
      );
    }
  }

  @override
  Future<Athlete> getAthleteById(String leagueId, String athleteId) async {
    try {
      final url =
          'http://sports.core.api.espn.com/v2/sports/soccer/leagues/$leagueId/seasons/2024/athletes/$athleteId?lang=en&region=us';

      dev.log('Fetching athlete from: $url');
      // Use cache with athlete cache duration
      final response = await _apiService.get(
        url,
        cacheDuration: _athleteCacheDuration,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Athlete.fromJson(data);
      } else {
        throw Exception('Failed to load athlete data: ${response.statusCode}');
      }
    } catch (e, stack) {
      return _errorHandler.handleError<Athlete>(
        e,
        stack,
        'getAthleteById',
        defaultValue: Athlete(
          id: 0,
          fullName: 'Unknown Player',
          dateOfBirth: '2000-01-01',
          country: 'Unknown',
          stats: Stats.empty(),
          club: Club.empty(),
        ),
      );
    }
  }
}
