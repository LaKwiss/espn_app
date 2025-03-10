import 'dart:convert';
import 'dart:developer';
import 'package:equatable/equatable.dart';
import 'package:espn_app/class/club.dart';
import 'package:espn_app/class/league.dart';
import 'package:espn_app/class/probability.dart';
import 'package:espn_app/class/score.dart';
import 'package:http/http.dart' as http;

class Event extends Equatable {
  final String id;
  final (String away, String home) idTeam;
  final String name;
  final String shortName; // Nom raccourci complet (ex.: "SCF @ FCA")
  final (String away, String home)
  teamsShortName; // Détail séparé des noms courts
  final String date;
  final String location;
  final String league;
  final bool isFinished;
  final (Future<Score> away, Future<Score> home) score;
  final (
    Future<Probability> away,
    Future<Probability> draw,
    Future<Probability> home,
  )
  probability;

  // Nouvelle propriété pour les clubs
  final Club? homeClub;
  final Club? awayClub;

  const Event({
    required this.id,
    required this.idTeam,
    required this.name,
    required this.shortName,
    required this.teamsShortName,
    required this.date,
    required this.location,
    required this.league,
    required this.score,
    required this.probability,
    this.isFinished = false,
    this.homeClub,
    this.awayClub,
  });

  /// Crée un Event à partir de deux JSON : l'un pour l'événement, l'autre pour les odds.
  /// On extrait également le champ "shortName" de l'événement et on le scinde pour obtenir
  /// les noms courts pour l'équipe à l'extérieur et à domicile.
  factory Event.fromJson(
    Map<String, dynamic> eventJson,
    Map<String, dynamic> oddsJson,
  ) {
    final competition = eventJson['competitions'][0];

    // Récupération des URLs de score pour chaque compétiteur
    final String homeScoreUrl =
        competition['competitors'][0]['score']['\$ref'] as String;
    final String awayScoreUrl =
        competition['competitors'][1]['score']['\$ref'] as String;

    // Extraction du shortName global et séparation en deux noms.
    final String eventShortName = eventJson['shortName'] as String;
    final parts = eventShortName.split('@');
    if (parts.length != 2) {
      throw Exception(
        "Le format de shortName n'est pas reconnu: $eventShortName",
      );
    }
    final String awayShort = parts[0].trim();
    final String homeShort = parts[1].trim();

    // Calcul des probabilités basées sur les odds
    var (
      double normAway,
      double normHome,
      double normDraw,
    ) = _calculateProbabilities(oddsJson);

    // Création des futures de probabilités
    final Future<Probability> awayProb = Future.value(
      Probability(value: normAway),
    );
    final Future<Probability> homeProb = Future.value(
      Probability(value: normHome),
    );
    final Future<Probability> drawProb = Future.value(
      Probability(value: normDraw),
    );

    // Récupération des informations des clubs si disponibles
    Club? homeClub;
    Club? awayClub;

    try {
      // Si les données de clubs sont disponibles dans le JSON, les extraire
      if (competition['competitors'][0].containsKey('team') &&
          competition['competitors'][0]['team'] != null) {
        final homeTeamData = competition['competitors'][0]['team'];
        final homeLeagueData = _extractLeagueData(homeTeamData);

        homeClub = Club(
          id: homeTeamData['id'] ?? 0,
          name: homeTeamData['displayName'] ?? 'Unknown',
          logo:
              homeTeamData['logos'] != null &&
                      homeTeamData['logos'] is List &&
                      homeTeamData['logos'].isNotEmpty
                  ? homeTeamData['logos'][0]['href']
                  : 'https://a.espncdn.com/i/teamlogos/soccer/500/${competition['competitors'][0]['id']}.png',
          country: homeTeamData['location'] ?? 'Unknown',
          flag: '', // Pas disponible directement dans les données
          league: homeLeagueData,
        );
      }

      if (competition['competitors'][1].containsKey('team') &&
          competition['competitors'][1]['team'] != null) {
        final awayTeamData = competition['competitors'][1]['team'];
        final awayLeagueData = _extractLeagueData(awayTeamData);

        awayClub = Club(
          id: awayTeamData['id'] ?? 0,
          name: awayTeamData['displayName'] ?? 'Unknown',
          logo:
              awayTeamData['logos'] != null &&
                      awayTeamData['logos'] is List &&
                      awayTeamData['logos'].isNotEmpty
                  ? awayTeamData['logos'][0]['href']
                  : 'https://a.espncdn.com/i/teamlogos/soccer/500/${competition['competitors'][1]['id']}.png',
          country: awayTeamData['location'] ?? 'Unknown',
          flag: '', // Pas disponible directement dans les données
          league: awayLeagueData,
        );
      }
    } catch (e) {
      print('Erreur lors de l\'extraction des données des clubs: $e');
      // On continue sans les données de club
    }

    log('le match est fini : ${competition['status']?['type']?['name']}');

    return Event(
      id: eventJson['id'].toString(),
      idTeam: (
        competition['competitors'][0]['id'].toString(),
        competition['competitors'][1]['id'].toString(),
      ),
      name: eventJson['name'] as String,
      shortName: eventShortName,
      teamsShortName: (awayShort, homeShort),
      date: eventJson['date'] as String,
      location:
          competition['venue']['shortName'] ?? competition['venue']['fullName'],
      league: eventJson['league']['\$ref'] as String,
      isFinished:
          competition['status']?['type']?['name'] == "STATUS_FINAL" ||
          competition['status']?['type']?['state'] == "post" ||
          (competition['recapAvailable'] == true ||
              competition['liveAvailable'] == false ||
              DateTime.parse(
                eventJson['date'],
              ).isBefore(DateTime.now().subtract(Duration(hours: 3)))),
      score: (Score.fetchScore(homeScoreUrl), Score.fetchScore(awayScoreUrl)),
      probability: (
        homeProb, // victoire à domicile
        drawProb, // match nul
        awayProb, // victoire à l'extérieur
      ),
      homeClub: homeClub,
      awayClub: awayClub,
    );
  }

  /// Extrait les données de la ligue à partir des données d'équipe
  static League _extractLeagueData(Map<String, dynamic> teamData) {
    if (teamData.containsKey('league') && teamData['league'] != null) {
      final leagueData = teamData['league'];
      return League(
        id: leagueData['id'] ?? 0,
        name: leagueData['name'] ?? 'Unknown',
        displayName: leagueData['displayName'] ?? 'Unknown',
        logo:
            leagueData['logos'] != null &&
                    leagueData['logos'] is List &&
                    leagueData['logos'].isNotEmpty
                ? leagueData['logos'][0]['href']
                : '',
        country:
            leagueData.containsKey('country')
                ? leagueData['country']['name'] ?? 'Unknown'
                : 'Unknown',
        flag:
            leagueData.containsKey('country')
                ? leagueData['country']['flag'] ?? ''
                : '',
        shortName: leagueData['shortName'] ?? '',
      );
    }

    // Si pas de données de ligue, créer une ligue par défaut
    return const League(
      id: 0,
      name: 'Unknown',
      displayName: 'Unknown',
      logo: '',
      country: 'Unknown',
      flag: '',
      shortName: '',
    );
  }

  /// Calcule les probabilités à partir du JSON des odds
  /// Essaie d'abord d'utiliser Bet365 (id "2000"), puis ESPN BET (id "58") si non disponible
  static (double away, double home, double draw) _calculateProbabilities(
    Map<String, dynamic> oddsJson,
  ) {
    // Vérification que la structure JSON est valide
    if (!oddsJson.containsKey('items') ||
        oddsJson['items'] is! List ||
        (oddsJson['items'] as List).isEmpty) {
      // Retourner des probabilités par défaut si la structure n'est pas valide
      print(
        'Structure JSON des odds invalide ou vide, utilisation des probabilités par défaut',
      );
      return (0.33, 0.33, 0.34);
    }

    final List items = oddsJson['items'] as List;
    Map<String, dynamic>? providerOdds;

    // Essayer d'abord de trouver Bet365 (id "2000")
    try {
      // Recherche sécurisée avec vérification de la structure
      for (var item in items) {
        if (item is Map<String, dynamic> &&
            item.containsKey('provider') &&
            item['provider'] is Map<String, dynamic> &&
            item['provider'].containsKey('id') &&
            item['provider']['id'].toString() == '2000') {
          providerOdds = item;
          break;
        }
      }

      // Format Bet365
      if (providerOdds != null &&
          providerOdds.containsKey('awayTeamOdds') &&
          providerOdds.containsKey('homeTeamOdds') &&
          providerOdds.containsKey('drawOdds')) {
        // Extraction des cotes avec vérification de la structure
        var awayOddsValue = _extractOddsValue(providerOdds, 'awayTeamOdds');
        var homeOddsValue = _extractOddsValue(providerOdds, 'homeTeamOdds');
        var drawOddsValue = _extractDrawOddsValue(providerOdds);

        if (awayOddsValue != null &&
            homeOddsValue != null &&
            drawOddsValue != null) {
          return _normalizeProbabilities(
            awayOddsValue,
            homeOddsValue,
            drawOddsValue,
          );
        }
      }
    } catch (e) {
      print('Erreur lors de la recherche de Bet365: $e');
      // Bet365 non trouvé ou structure incorrecte, on continue avec ESPN BET
    }

    // Essayer ensuite ESPN BET (id "58") si Bet365 n'est pas disponible
    try {
      // Recherche sécurisée pour ESPN BET
      providerOdds = null; // Reset
      for (var item in items) {
        if (item is Map<String, dynamic> &&
            item.containsKey('provider') &&
            item['provider'] is Map<String, dynamic> &&
            item['provider'].containsKey('id') &&
            item['provider']['id'].toString() == '58') {
          providerOdds = item;
          break;
        }
      }

      if (providerOdds != null) {
        // Format ESPN BET - les valeurs sont stockées différemment
        double? awayOdds, homeOdds, drawOdds;

        // Méthode 1: Vérifier les moneyLine directs
        if (_canAccessPath(providerOdds, ['awayTeamOdds', 'moneyLine']) &&
            _canAccessPath(providerOdds, ['homeTeamOdds', 'moneyLine']) &&
            _canAccessPath(providerOdds, ['drawOdds', 'moneyLine'])) {
          // American odds to decimal conversion
          awayOdds = _americanToDecimalOdds(
            providerOdds['awayTeamOdds']['moneyLine'],
          );
          homeOdds = _americanToDecimalOdds(
            providerOdds['homeTeamOdds']['moneyLine'],
          );
          drawOdds = _americanToDecimalOdds(
            providerOdds['drawOdds']['moneyLine'],
          );
        }
        // Méthode 2: Chercher dans current.moneyLine
        else if (_canAccessPath(providerOdds, [
              'awayTeamOdds',
              'current',
              'moneyLine',
              'decimal',
            ]) &&
            _canAccessPath(providerOdds, [
              'homeTeamOdds',
              'current',
              'moneyLine',
              'decimal',
            ]) &&
            _canAccessPath(providerOdds, ['current', 'draw', 'decimal'])) {
          // Already decimal odds
          awayOdds =
              providerOdds['awayTeamOdds']['current']['moneyLine']['decimal'];
          homeOdds =
              providerOdds['homeTeamOdds']['current']['moneyLine']['decimal'];
          drawOdds = providerOdds['current']['draw']['decimal'];
        }
        // Méthode 3: Chercher dans current.value
        else if (_canAccessPath(providerOdds, [
              'awayTeamOdds',
              'current',
              'moneyLine',
              'value',
            ]) &&
            _canAccessPath(providerOdds, [
              'homeTeamOdds',
              'current',
              'moneyLine',
              'value',
            ]) &&
            _canAccessPath(providerOdds, ['current', 'draw', 'value'])) {
          awayOdds =
              providerOdds['awayTeamOdds']['current']['moneyLine']['value'];
          homeOdds =
              providerOdds['homeTeamOdds']['current']['moneyLine']['value'];
          drawOdds = providerOdds['current']['draw']['value'];
        }
        // Méthode 4: Chercher des american odds
        else if (_canAccessPath(providerOdds, [
              'awayTeamOdds',
              'current',
              'moneyLine',
              'american',
            ]) &&
            _canAccessPath(providerOdds, [
              'homeTeamOdds',
              'current',
              'moneyLine',
              'american',
            ]) &&
            _canAccessPath(providerOdds, ['current', 'draw', 'american'])) {
          String awayAmerican =
              providerOdds['awayTeamOdds']['current']['moneyLine']['american'];
          String homeAmerican =
              providerOdds['homeTeamOdds']['current']['moneyLine']['american'];
          String drawAmerican = providerOdds['current']['draw']['american'];

          // Convertir de format américain à décimal
          awayOdds = _americanStringToDecimalOdds(awayAmerican);
          homeOdds = _americanStringToDecimalOdds(homeAmerican);
          drawOdds = _americanStringToDecimalOdds(drawAmerican);
        }

        // Si on a réussi à extraire toutes les cotes
        if (awayOdds != null && homeOdds != null && drawOdds != null) {
          return _normalizeProbabilities(awayOdds, homeOdds, drawOdds);
        }
      }
    } catch (e) {
      print('Erreur lors de la recherche d\'ESPN BET: $e');
      // ESPN BET non trouvé ou erreur de traitement
    }

    // Si aucun provider n'est disponible ou utilisable, retourner des probabilités par défaut
    return (0.33, 0.33, 0.34);
  }

  /// Méthode utilitaire pour vérifier si un chemin d'accès existe dans un Map
  static bool _canAccessPath(Map<String, dynamic> map, List<String> path) {
    dynamic current = map;

    for (var key in path) {
      if (current is! Map || !current.containsKey(key)) {
        return false;
      }
      current = current[key];
      if (current == null) {
        return false;
      }
    }

    return true;
  }

  /// Extraire la valeur de cote de manière sécurisée
  static double? _extractOddsValue(
    Map<String, dynamic> providerOdds,
    String teamKey,
  ) {
    try {
      // Essayer d'abord le format direct avec 'odds.value'
      if (_canAccessPath(providerOdds, [teamKey, 'odds', 'value'])) {
        var value = providerOdds[teamKey]['odds']['value'];
        return value is num
            ? value.toDouble()
            : double.tryParse(value.toString());
      }

      // Essayer ensuite avec 'current.moneyLine.value'
      if (_canAccessPath(providerOdds, [
        teamKey,
        'current',
        'moneyLine',
        'value',
      ])) {
        var value = providerOdds[teamKey]['current']['moneyLine']['value'];
        return value is num
            ? value.toDouble()
            : double.tryParse(value.toString());
      }

      // Essayer le format 'current.moneyLine.decimal'
      if (_canAccessPath(providerOdds, [
        teamKey,
        'current',
        'moneyLine',
        'decimal',
      ])) {
        var value = providerOdds[teamKey]['current']['moneyLine']['decimal'];
        return value is num
            ? value.toDouble()
            : double.tryParse(value.toString());
      }

      // Essayer avec moneyLine directement
      if (_canAccessPath(providerOdds, [teamKey, 'moneyLine'])) {
        var value = providerOdds[teamKey]['moneyLine'];
        if (value is num) {
          return _americanToDecimalOdds(value);
        }
      }

      return null;
    } catch (e) {
      print('Erreur lors de l\'extraction des cotes pour $teamKey: $e');
      return null;
    }
  }

  /// Extraire la valeur de cote pour le match nul de manière sécurisée
  static double? _extractDrawOddsValue(Map<String, dynamic> providerOdds) {
    try {
      // Format Bet365
      if (_canAccessPath(providerOdds, ['drawOdds', 'value'])) {
        var value = providerOdds['drawOdds']['value'];
        return value is num
            ? value.toDouble()
            : double.tryParse(value.toString());
      }

      // Format avec moneyLine
      if (_canAccessPath(providerOdds, ['drawOdds', 'moneyLine'])) {
        var value = providerOdds['drawOdds']['moneyLine'];
        return value is num ? _americanToDecimalOdds(value) : null;
      }

      // Format ESPN avec current
      if (_canAccessPath(providerOdds, ['current', 'draw', 'value'])) {
        var value = providerOdds['current']['draw']['value'];
        return value is num
            ? value.toDouble()
            : double.tryParse(value.toString());
      }

      // Format ESPN avec decimal
      if (_canAccessPath(providerOdds, ['current', 'draw', 'decimal'])) {
        var value = providerOdds['current']['draw']['decimal'];
        return value is num
            ? value.toDouble()
            : double.tryParse(value.toString());
      }

      return null;
    } catch (e) {
      print('Erreur lors de l\'extraction des cotes pour le match nul: $e');
      return null;
    }
  }

  /// Convertit les cotes américaines (numériques) en cotes décimales
  static double _americanToDecimalOdds(dynamic americanOdds) {
    if (americanOdds == null) return 2.0;

    try {
      final num value =
          (americanOdds is num)
              ? americanOdds
              : double.parse(americanOdds.toString());

      if (value > 0) {
        return 1 + (value / 100);
      } else if (value < 0) {
        return 1 + (100 / -value);
      } else {
        return 2.0; // Even odds
      }
    } catch (e) {
      print('Erreur de conversion des cotes américaines: $e');
      return 2.0; // Valeur par défaut en cas d'erreur
    }
  }

  /// Convertit les cotes américaines (en format string) en cotes décimales
  static double _americanStringToDecimalOdds(String americanOdds) {
    if (americanOdds == "EVEN") return 2.0;

    try {
      // Enlever les caractères non numériques sauf le signe moins
      String cleaned = americanOdds.replaceAll(RegExp(r'[^0-9\-]'), '');

      if (cleaned.isEmpty) return 2.0;

      int value = int.parse(cleaned);

      if (value > 0) {
        return 1 + (value / 100);
      } else if (value < 0) {
        return 1 + (100 / -value);
      } else {
        return 2.0; // Even odds
      }
    } catch (e) {
      print('Erreur de conversion des cotes américaines (string): $e');
      return 2.0; // Valeur par défaut en cas d'erreur
    }
  }

  /// Calcule les probabilités normalisées à partir des cotes décimales
  static (double away, double home, double draw) _normalizeProbabilities(
    double awayOdds,
    double homeOdds,
    double drawOdds,
  ) {
    // Calcul des probabilités brutes (inverse des cotes)
    final double rawAway = 1 / awayOdds;
    final double rawHome = 1 / homeOdds;
    final double rawDraw = 1 / drawOdds;

    // Normalisation pour que la somme soit 1
    final double totalRaw = rawAway + rawHome + rawDraw;
    final double normAway = rawAway / totalRaw;
    final double normHome = rawHome / totalRaw;
    final double normDraw = rawDraw / totalRaw;

    return (normAway, normHome, normDraw);
  }

  /// Méthode asynchrone qui récupère l'événement ET les odds depuis deux endpoints différents.
  static Future<Event> fetchEvent(String eventUrl, String oddsUrl) async {
    // Récupérer le JSON de l'événement.
    final eventResponse = await http.get(Uri.parse(eventUrl));
    if (eventResponse.statusCode != 200) {
      throw Exception('Erreur lors de la récupération de l\'événement');
    }
    final eventJson = jsonDecode(eventResponse.body) as Map<String, dynamic>;

    // Récupérer le JSON des odds.
    final oddsResponse = await http.get(Uri.parse(oddsUrl));
    if (oddsResponse.statusCode != 200) {
      throw Exception('Erreur lors de la récupération des odds');
    }
    final oddsJson = jsonDecode(oddsResponse.body) as Map<String, dynamic>;

    // Créer l'Event en combinant les deux sources.
    return Event.fromJson(eventJson, oddsJson);
  }

  /// Obtenir le club par défaut pour une équipe à partir de son ID
  Club getDefaultClub(String teamId) {
    return Club(
      id: int.tryParse(teamId) ?? 0,
      name: 'Team $teamId',
      logo: 'https://a.espncdn.com/i/teamlogos/soccer/500/$teamId.png',
      country: 'Unknown',
      flag: '',
      league: const League(
        id: 0,
        name: 'Unknown League',
        displayName: 'Unknown League',
        logo: '',
        country: 'Unknown',
        flag: '',
        shortName: 'UNK',
      ),
    );
  }

  /// Getter pour accéder facilement au club domicile
  Club get club => homeClub ?? getDefaultClub(idTeam.$2);

  @override
  List<Object?> get props => [
    id,
    name,
    shortName,
    date,
    location,
    league,
    homeClub,
    awayClub,
  ];
}
