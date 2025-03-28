import 'dart:convert';
import 'package:espn_app/repositories/league_picture_repository/i_league_repository.dart';
import 'package:espn_app/services/api_service.dart';
import 'package:espn_app/services/error_handler_service.dart';

class LeaguePictureRepository implements ILeaguePictureRepository {
  final ApiService _apiService;
  final ErrorHandlerService _errorHandler;

  // League logos rarely change, so we can cache them for a longer period
  static const Duration _leagueLogoCacheDuration = Duration(days: 7);

  LeaguePictureRepository({
    required ApiService apiService,
    required ErrorHandlerService errorHandler,
  }) : _apiService = apiService,
       _errorHandler = errorHandler;

  @override
  Future<String> getUrlByLeagueCode(String code) async {
    try {
      final url =
          'http://sports.core.api.espn.com/v2/sports/soccer/leagues/$code';

      // Use a longer cache duration for league data
      final response = await _apiService.get(
        url,
        useCache: true,
        cacheDuration: _leagueLogoCacheDuration,
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return json['logos'][1]['href'] as String;
      } else {
        throw Exception('Failed to load league logo: ${response.statusCode}');
      }
    } catch (e, stack) {
      return _errorHandler.handleError<String>(
        e,
        stack,
        'getUrlByLeagueCode',
        defaultValue:
            'https://a.espncdn.com/i/leaguelogos/soccer/500/2.png', // Valeur par défaut en cas d'erreur
      );
    }
  }
}
