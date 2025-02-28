import 'package:equatable/equatable.dart';
import 'package:espn_app/class/club.dart';
import 'package:espn_app/class/stats.dart';

class Athlete extends Equatable {
  final int id;
  final String fullName;
  final String dateOfBirth;
  final String country;
  final Stats stats;
  final Club club;

  const Athlete({
    required this.id,
    required this.fullName,
    required this.dateOfBirth,
    required this.country,
    required this.stats,
    required this.club,
  });

  factory Athlete.fromJson(Map<String, dynamic> json) {
    return Athlete(
      id: json['id'],
      fullName: json['full_name'],
      dateOfBirth: json['date_of_birth'],
      country: json['country'],
      stats: Stats.fromJson(json['stats']),
      club: Club.fromJson(json['club']),
    );
  }

  @override
  List<Object?> get props => [id, fullName, dateOfBirth, country, stats, club];
}
