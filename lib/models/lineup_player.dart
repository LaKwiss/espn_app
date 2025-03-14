// lib/models/lineup_player.dart
import 'package:equatable/equatable.dart';

class LineupPlayer extends Equatable {
  final String id;
  final String jersey;
  final bool isStarter;
  final String positionId;
  final String formationPlace;
  final String athleteRef;

  const LineupPlayer({
    required this.id,
    required this.jersey,
    required this.isStarter,
    required this.positionId,
    required this.formationPlace,
    required this.athleteRef,
  });

  factory LineupPlayer.fromJson(Map<String, dynamic> json) {
    String athleteRef = '';
    if (json.containsKey('athlete') &&
        json['athlete'] != null &&
        json['athlete'].containsKey('\$ref')) {
      athleteRef = json['athlete']['\$ref'];
    }

    String positionId = '';
    if (json.containsKey('position') &&
        json['position'] != null &&
        json['position'].containsKey('\$ref')) {
      final posRef = json['position']['\$ref'];
      final parts = posRef.split('/');
      positionId = parts.isNotEmpty ? parts.last : '';
    }

    return LineupPlayer(
      id: json['playerId']?.toString() ?? '',
      jersey: json['jersey'] ?? '',
      isStarter: json['starter'] ?? false,
      positionId: positionId,
      formationPlace: json['formationPlace'] ?? '0',
      athleteRef: athleteRef,
    );
  }

  @override
  List<Object?> get props => [
    id,
    jersey,
    isStarter,
    positionId,
    formationPlace,
    athleteRef,
  ];

  static LineupPlayer empty() {
    return LineupPlayer(
      id: '',
      jersey: '',
      isStarter: false,
      positionId: '',
      formationPlace: '0',
      athleteRef: '',
    );
  }
}
