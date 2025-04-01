import 'dart:convert';
import 'dart:developer';
import 'package:equatable/equatable.dart';
import 'package:espn_app/models/club.dart';
import 'package:espn_app/models/league.dart';
import 'package:espn_app/models/probability.dart';
import 'package:espn_app/models/score.dart';
import 'package:http/http.dart' as http;
import 'package:espn_app/services/odds_service.dart';

class Event extends Equatable {
  final String id;
  final (String away, String home) idTeam;
  final String name;
  final String shortName;
  final (String away, String home) teamsShortName;
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

  factory Event.fromJson(
    Map<String, dynamic> eventJson,
    Map<String, dynamic> oddsJson,
  ) {
    final competition = eventJson['competitions'][0];

    final String homeScoreUrl =
        competition['competitors'][0]['score']['\$ref'] as String;
    final String awayScoreUrl =
        competition['competitors'][1]['score']['\$ref'] as String;

    final String eventShortName = eventJson['shortName'] as String;
    final parts = eventShortName.split('@');
    if (parts.length != 2) {
      throw Exception("Invalid shortName format: $eventShortName");
    }
    final String awayShort = parts[0].trim();
    final String homeShort = parts[1].trim();

    final (
      double awayProb,
      double homeProb,
      double drawProb,
    ) = OddsService.calculateProbabilities(oddsJson);

    final Future<Probability> awayProbability = Future.value(
      Probability(value: awayProb),
    );
    final Future<Probability> homeProbability = Future.value(
      Probability(value: homeProb),
    );
    final Future<Probability> drawProbability = Future.value(
      Probability(value: drawProb),
    );

    Club? homeClub;
    Club? awayClub;

    try {
      homeClub = _extractClubData(competition['competitors'][0]);
      awayClub = _extractClubData(competition['competitors'][1]);
    } catch (e) {
      log('Error extracting club data: $e');
    }

    bool isFinished = _determineMatchStatus(eventJson, competition);

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
      isFinished: isFinished,
      score: (Score.fetchScore(awayScoreUrl), Score.fetchScore(homeScoreUrl)),
      probability: (homeProbability, drawProbability, awayProbability),
      homeClub: homeClub,
      awayClub: awayClub,
    );
  }

  static Club? _extractClubData(Map<String, dynamic> competitor) {
    if (!competitor.containsKey('team') || competitor['team'] == null) {
      return null;
    }

    final teamData = competitor['team'];
    final League leagueData = _extractLeagueData(teamData);

    return Club(
      id: teamData['id'] ?? 0,
      name: teamData['displayName'] ?? 'Unknown',
      logo: _extractLogo(teamData, competitor['id']),
      country: teamData['location'] ?? 'Unknown',
      flag: '', // Not directly available in data
      league: leagueData,
    );
  }

  static League _extractLeagueData(Map<String, dynamic> teamData) {
    if (teamData.containsKey('league') && teamData['league'] != null) {
      final leagueData = teamData['league'];
      return League(
        id: leagueData['id'] ?? 0,
        name: leagueData['name'] ?? 'Unknown',
        displayName: leagueData['displayName'] ?? 'Unknown',
        logo: _extractLogo(leagueData, 0),
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

  static String _extractLogo(Map<String, dynamic> data, dynamic fallbackId) {
    return data['logos'] != null &&
            data['logos'] is List &&
            (data['logos'] as List).isNotEmpty
        ? data['logos'][0]['href']
        : 'https://a.espncdn.com/i/teamlogos/soccer/500/$fallbackId.png';
  }

  static bool _determineMatchStatus(
    Map<String, dynamic> eventJson,
    Map<String, dynamic> competition,
  ) {
    return competition['status']?['type']?['name'] == "STATUS_FINAL" ||
        competition['status']?['type']?['state'] == "post" ||
        (competition['recapAvailable'] == true ||
            competition['liveAvailable'] == false ||
            DateTime.parse(
              eventJson['date'],
            ).isBefore(DateTime.now().subtract(const Duration(hours: 3))));
  }

  static Future<Event> fetchEvent(String eventUrl, String oddsUrl) async {
    // Fetch event data
    final eventResponse = await http.get(Uri.parse(eventUrl));
    if (eventResponse.statusCode != 200) {
      throw Exception('Failed to fetch event data');
    }
    final eventJson = jsonDecode(eventResponse.body) as Map<String, dynamic>;

    final oddsResponse = await http.get(Uri.parse(oddsUrl));
    if (oddsResponse.statusCode != 200) {
      throw Exception('Failed to fetch odds data');
    }
    final oddsJson = jsonDecode(oddsResponse.body) as Map<String, dynamic>;

    return Event.fromJson(eventJson, oddsJson);
  }

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
