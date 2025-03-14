import 'package:equatable/equatable.dart';
import 'package:espn_app/models/lineup_player.dart';

class Lineup extends Equatable {
  final String formation;
  final String formationSummary;
  final List<LineupPlayer> players;

  const Lineup({
    required this.formation,
    required this.formationSummary,
    required this.players,
  });

  factory Lineup.fromJson(Map<String, dynamic> json) {
    String formation = '4-3-3'; // Formation par défaut
    String formationSummary = '4-3-3';

    if (json.containsKey('formation') && json['formation'] != null) {
      if (json['formation'].containsKey('id')) {
        formation = json['formation']['id'];
      }
      if (json['formation'].containsKey('summary')) {
        formationSummary = json['formation']['summary'];
      }
    }

    List<LineupPlayer> players = [];
    if (json.containsKey('entries') && json['entries'] is List) {
      players =
          (json['entries'] as List)
              .map((entry) => LineupPlayer.fromJson(entry))
              .toList();
    }

    return Lineup(
      formation: formation,
      formationSummary: formationSummary,
      players: players,
    );
  }

  /// Crée une instance vide pour les cas d'erreur
  factory Lineup.empty() {
    return const Lineup(
      formation: '4-3-3',
      formationSummary: '4-3-3',
      players: [],
    );
  }

  @override
  List<Object?> get props => [formation, formationSummary, players];
}
