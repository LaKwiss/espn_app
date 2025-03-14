import 'package:equatable/equatable.dart';

class League extends Equatable {
  final int id;
  final String name;
  final String displayName;
  final String logo;
  final String country;
  final String flag;
  final String shortName;

  const League({
    required this.id,
    required this.name,
    required this.displayName,
    required this.logo,
    required this.country,
    required this.flag,
    required this.shortName,
  });

  factory League.fromJson(Map<String, dynamic> json) {
    return League(
      id: json['id'],
      name: json['name'],
      displayName: json['displayName'],
      logo: json['logos']['href'],
      country: json['country']['name'],
      flag: json['country']['flag'],
      shortName: json['short_name'],
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    displayName,
    logo,
    country,
    flag,
    shortName,
  ];

  static empty() {
    return League(
      id: 0,
      name: 'Unknown League',
      displayName: 'Unknown League',
      logo: '',
      country: 'Unknown',
      flag: '',
      shortName: 'Unknown',
    );
  }
}
