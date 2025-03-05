import 'dart:convert';
import 'package:http/http.dart' as http;

class Last5Repository {
  Future<List<int>> getLast5(String teamId) async {
    final url =
        'http://sports.core.api.espn.com/v2/sports/soccer/leagues/esp.1/seasons/2024/teams/$teamId';
    final response = await http.get(Uri.parse(url));

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
  }
}
