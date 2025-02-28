import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:espn_app/class/event.dart';

class EventRepository {
  static Future<List<Event>> fetchEventsFromLeague(String league) async {
    final response = await http.get(
      Uri.parse(
        'http://sports.core.api.espn.com/v2/sports/soccer/leagues/$league/events',
      ),
    );

    if (response.statusCode == 200) {
      // Décoder le corps de la réponse
      final Map<String, dynamic> data = jsonDecode(response.body);
      // Extraction des URLs depuis le champ "$ref" de chaque élément
      final List<dynamic> items = data['items'];
      final List<String> urls =
          items.map<String>((item) => item['\$ref'] as String).toList();

      // Pour chaque URL, on récupère les détails de l'événement.
      final futures =
          urls.map<Future<Event>>((url) async {
            final eventResponse = await http.get(Uri.parse(url));
            if (eventResponse.statusCode == 200) {
              final Map<String, dynamic> eventData = jsonDecode(
                eventResponse.body,
              );
              return Event.fromJson(eventData);
            } else {
              throw Exception(
                'Erreur lors du chargement de l\'événement depuis $url',
              );
            }
          }).toList();

      // Attendre que toutes les requêtes se terminent et retourner la liste d'événements
      final result = await Future.wait(futures);
      log('Récupération de ${result.length} événements pour la ligue: $league');
      return result;
    } else {
      throw Exception(
        'Erreur lors du chargement des événements pour la ligue: $league',
      );
    }
  }

  static Future<String> fetchLeagueName(String leagueName) async {
    final response = await http.get(
      Uri.parse(
        'http://sports.core.api.espn.com/v2/sports/soccer/leagues/$leagueName',
      ),
    );

    if (response.statusCode == 200) {
      // Décoder le corps de la réponse
      final Map<String, dynamic> data = jsonDecode(response.body);
      // Extraire le nom de la ligue depuis le champ "name"
      final String name = data['displayName'] as String;
      log('Nom de la ligue récupéré: $name');
      return name;
    } else {
      throw Exception('Erreur lors du chargement de la ligue: $leagueName');
    }
  }
}
