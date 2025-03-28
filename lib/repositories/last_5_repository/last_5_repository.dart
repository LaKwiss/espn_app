import 'dart:convert';
import 'package:espn_app/repositories/last_5_repository/i_last_5_repository.dart';
import 'package:espn_app/services/api_service.dart';
import 'package:espn_app/services/error_handler_service.dart';

class Last5Repository implements ILast5Repository {
  final ApiService _apiService;
  final ErrorHandlerService _errorHandler;

  // Last 5 games data can be cached for a few hours since it doesn't change often
  static const Duration _last5CacheDuration = Duration(hours: 6);

  Last5Repository({
    required ApiService apiService,
    required ErrorHandlerService errorHandler,
  }) : _apiService = apiService,
       _errorHandler = errorHandler;

  @override
  Future<List<int>> getLast5(String teamId) async {
    final url =
        'http://sports.core.api.espn.com/v2/sports/soccer/leagues/esp.1/seasons/2024/teams/$teamId';

    try {
      // Use cache for last 5 games data
      final response = await _apiService.get(
        url,
        cacheDuration: _last5CacheDuration,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final String form = data['form'] as String;
        // On suppose que la chaîne "form" a toujours une taille d'au moins 5.
        final List<int> results =
            form.split('').take(5).map((result) {
              if (result == 'W') return 3;
              if (result == 'D') return 1;
              if (result == 'L') return 0;
              return 0;
            }).toList();
        return results;
      } else {
        throw Exception('Erreur lors du chargement des données');
      }
    } catch (e, stack) {
      return _errorHandler.handleError<List<int>>(
        e,
        stack,
        'getLast5',
        defaultValue: List.filled(5, 0), // Valeur par défaut en cas d'erreur
      );
    }
  }
}
