import 'package:equatable/equatable.dart';
import 'package:espn_app/models/league.dart';

class Club extends Equatable {
  final int id;
  final String name;
  final String logo;
  final String country;
  final String flag;
  final League league;

  const Club({
    required this.id,
    required this.name,
    required this.logo,
    required this.country,
    required this.flag,
    required this.league,
  });

  factory Club.fromJson(Map<String, dynamic> json) {
    return Club(
      id: json['id'],
      name: json['name'],
      logo: json['logos']['href'],
      country: json['country']['name'],
      flag: json['country']['flag'],
      league: League.fromJson(json['league']),
    );
  }

  @override
  List<Object?> get props => [id, name, logo, country, flag, league];

  static empty() {
    return Club(
      id: 0,
      name: 'Unknown Club',
      logo: '',
      country: 'Unknown',
      flag: '',
      league: League.empty(),
    );
  }
}
