import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:espn_app/class/event.dart';

class EventRepository {
  /// Récupère la liste des événements pour une ligue donnée et
  /// pour chaque événement, charge également les odds pour récupérer les probabilités.
  static Future<List<Event>> fetchEventsFromLeague(String league) async {
    final response = await http.get(
      Uri.parse(
        'http://sports.core.api.espn.com/v2/sports/soccer/leagues/$league/events',
      ),
    );

    if (response.statusCode == 200) {
      // Décoder le corps de la réponse
      final Map<String, dynamic> data = jsonDecode(response.body);
      // Extraction des URLs depuis le champ "$ref" de chaque événement
      final List<dynamic> items = data['items'];
      final List<String> eventUrls =
          items.map<String>((item) => item['\$ref'] as String).toList();

      // Pour chaque URL d'événement, on récupère d'abord l'event, puis les odds associées
      final futures =
          eventUrls.map<Future<Event>>((url) async {
            // Charger l'événement
            final eventResponse = await http.get(Uri.parse(url));
            if (eventResponse.statusCode != 200) {
              throw Exception(
                "Erreur lors du chargement de l'événement depuis $url",
              );
            }
            final Map<String, dynamic> eventJson = jsonDecode(
              eventResponse.body,
            );
            // Récupérer l'URL des odds depuis la compétition de l'événement
            final competition = eventJson['competitions'][0];
            final oddsRef = competition['odds'];
            if (oddsRef == null || oddsRef['\$ref'] == null) {
              throw Exception("URL des odds introuvable pour l'événement $url");
            }
            final String oddsUrl = oddsRef['\$ref'] as String;
            // Charger les odds (contenant les cotes et donc les probabilités)
            final oddsResponse = await http.get(Uri.parse(oddsUrl));
            if (oddsResponse.statusCode != 200) {
              throw Exception(
                "Erreur lors du chargement des odds depuis $oddsUrl",
              );
            }
            final Map<String, dynamic> oddsJson = jsonDecode(oddsResponse.body);
            // Construire l'Event en combinant l'eventJson et les oddsJson
            return Event.fromJson(eventJson, oddsJson);
          }).toList();

      final result = await Future.wait(futures);
      log('Récupération de ${result.length} événements pour la ligue: $league');
      return result;
    } else {
      throw Exception(
        'Erreur lors du chargement des événements pour la ligue: $league',
      );
    }
  }

  /// Récupère le nom complet de la ligue à partir de son endpoint.
  static Future<String> fetchLeagueName(String leagueName) async {
    final response = await http.get(
      Uri.parse(
        'http://sports.core.api.espn.com/v2/sports/soccer/leagues/$leagueName',
      ),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final String name = data['displayName'] as String;
      log('Nom de la ligue récupéré: $name');
      return name;
    } else {
      throw Exception('Erreur lors du chargement de la ligue: $leagueName');
    }
  }
}
