import 'package:equatable/equatable.dart';
import 'package:espn_app/class/score.dart';

class Event extends Equatable {
  final String id;
  final (String away, String home) idTeam;
  final String name;
  final String date;
  final String location;
  final String league;
  final bool isFinished;
  final (Future<Score> away, Future<Score> home) score;

  const Event({
    required this.id,
    required this.idTeam,
    required this.name,
    required this.date,
    required this.location,
    required this.league,
    required this.score,
    this.isFinished = false,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    final competition = json['competitions'][0];
    final homeScoreUrl =
        competition['competitors'][0]['score']['\$ref'] as String;
    final awayScoreUrl =
        competition['competitors'][1]['score']['\$ref'] as String;

    return Event(
      id: json['id'] as String,
      idTeam: (
        json['competitions'][0]['competitors'][0]['id'] as String,
        json['competitions'][0]['competitors'][1]['id'] as String,
      ),
      name: json['name'] as String,
      date: json['date'] as String,
      location:
          competition['venue']['shortName'] as String? ??
          competition['venue']['fullName'] as String,
      league: json['league']['\$ref'] as String,
      isFinished:
          competition['recapAvailable'] == true &&
          competition['liveAvailable'] == false &&
          ((competition['competitors'][0]['winner'] == true) ||
              (competition['competitors'][1]['winner'] == true)),
      score: (Score.fetchScore(homeScoreUrl), Score.fetchScore(awayScoreUrl)),
    );
  }

  @override
  List<Object?> get props => [id, name, date, location, league];
}
