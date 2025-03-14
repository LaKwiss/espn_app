import 'package:equatable/equatable.dart';

class Stats extends Equatable {
  final int id;
  final int goals;
  final int assists;
  final int appearances;
  final int minutesPlayed;
  final int yellowCards;
  final int redCards;

  const Stats({
    required this.id,
    required this.goals,
    required this.assists,
    required this.appearances,
    required this.minutesPlayed,
    required this.yellowCards,
    required this.redCards,
  });

  factory Stats.fromJson(Map<String, dynamic> json) {
    return Stats(
      id: json['id'],
      goals: json['goals'],
      assists: json['assists'],
      appearances: json['appearances'],
      minutesPlayed: json['minutes_played'],
      yellowCards: json['yellow_cards'],
      redCards: json['red_cards'],
    );
  }

  @override
  List<Object?> get props => [
    id,
    goals,
    assists,
    appearances,
    minutesPlayed,
    yellowCards,
    redCards,
  ];

  static empty() {
    return Stats(
      id: 0,
      goals: 0,
      assists: 0,
      appearances: 0,
      minutesPlayed: 0,
      yellowCards: 0,
      redCards: 0,
    );
  }
}
