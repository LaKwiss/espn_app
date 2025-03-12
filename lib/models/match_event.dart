import 'package:equatable/equatable.dart';

enum MatchEventType {
  goal,
  yellowCard,
  redCard,
  substitution,
  penalty,
  missedPenalty,
  ownGoal,
  start,
  end,
  kickoff,
  foul,
  freeKick,
  throwIn,
  shotBlocked,
  save,
  shotOffTarget,
  blockedPass,
  handball,
  assistsShot,
  unknown,
}

enum MatchEventPeriod {
  firstHalf,
  secondHalf,
  firstExtraTime,
  secondExtraTime,
  penaltyShootout,
}

class MatchEvent extends Equatable {
  final String id;
  final MatchEventType type;
  final String text;
  final String? shortText;
  final String alternateText;
  final String? shortAlternateText;
  final String time;
  final MatchEventPeriod period;
  final (int away, int home) score;
  final (String away, String home)
  teams; // Tuple contenant les IDs des équipes away et home
  final bool isScoring;
  final bool isPriority;
  final DateTime wallClock;
  final String? teamId;
  final List<MatchEventParticipant> participants;
  final double? fieldPositionX;
  final double? fieldPositionY;

  const MatchEvent({
    required this.id,
    required this.type,
    required this.text,
    this.shortText,
    required this.alternateText,
    this.shortAlternateText,
    required this.time,
    required this.period,
    required this.score,
    required this.teams,
    required this.isScoring,
    required this.isPriority,
    required this.wallClock,
    this.teamId,
    required this.participants,
    this.fieldPositionX,
    this.fieldPositionY,
  });

  @override
  List<Object?> get props => [
    id,
    type,
    text,
    alternateText,
    time,
    period,
    score,
    teams,
    isScoring,
    wallClock,
    teamId,
    participants,
  ];

  static MatchEventType _parseEventType(Map<String, dynamic> typeData) {
    final typeId = typeData['id'];
    switch (typeId) {
      case '80':
        return MatchEventType.kickoff;
      case '66':
        return MatchEventType.foul;
      case '96':
        return MatchEventType.freeKick;
      case '124':
        return MatchEventType.throwIn;
      case '135':
        return MatchEventType.shotBlocked;
      case '77':
        return MatchEventType.save;
      case '117':
        return MatchEventType.shotOffTarget;
      case '162':
        return MatchEventType.blockedPass;
      case '141':
        return MatchEventType.assistsShot;
      case '122':
        return MatchEventType.handball;
      // Ajoutez les autres types selon les données que vous recevez
      case '1':
        return MatchEventType.goal;
      case '2':
        return MatchEventType.yellowCard;
      case '3':
        return MatchEventType.redCard;
      case '4':
        return MatchEventType.substitution;
      case '5':
        return MatchEventType.penalty;
      case '6':
        return MatchEventType.missedPenalty;
      case '7':
        return MatchEventType.ownGoal;
      default:
        return MatchEventType.unknown;
    }
  }

  static MatchEventPeriod _parsePeriod(int periodNumber) {
    switch (periodNumber) {
      case 1:
        return MatchEventPeriod.firstHalf;
      case 2:
        return MatchEventPeriod.secondHalf;
      case 3:
        return MatchEventPeriod.firstExtraTime;
      case 4:
        return MatchEventPeriod.secondExtraTime;
      case 5:
        return MatchEventPeriod.penaltyShootout;
      default:
        return MatchEventPeriod.firstHalf;
    }
  }

  factory MatchEvent.fromJson(
    Map<String, dynamic> json, {
    required (String away, String home) teams,
  }) {
    // Extraire l'heure formatée du temps de jeu
    final clockValue = json['clock']['value'] as double;
    final minutes = (clockValue / 60).floor();
    final displayTime =
        json['clock']['displayValue'] as String? ?? '$minutes\'';

    // Extraire la période
    final periodNumber = json['period']['number'] as int;
    final period = _parsePeriod(periodNumber);

    // Extraire l'ID de l'équipe si disponible
    String? teamId;
    if (json.containsKey('team') && json['team'] != null) {
      final teamRef = json['team']['\$ref'] as String;
      final parts = teamRef.split('/');
      teamId = parts.isNotEmpty ? parts.last : null;
    }

    // Extraire les participants
    final participants = <MatchEventParticipant>[];
    if (json.containsKey('participants') && json['participants'] is List) {
      for (final participantJson in json['participants']) {
        participants.add(MatchEventParticipant.fromJson(participantJson));
      }
    }

    return MatchEvent(
      id: json['id'] ?? '',
      type: _parseEventType(json['type']),
      text: json['text'] ?? json['type']['text'] ?? 'Kickoff',
      shortText: json['shortText'] as String?,
      alternateText: json['alternativeText'] ?? 'Kickoff',
      shortAlternateText: json['shortAlternativeText'] as String?,
      time: displayTime,
      period: period,
      score: (json['awayScore'] as int? ?? 0, json['homeScore'] as int? ?? 0),
      teams: teams,
      isScoring: json['scoringPlay'] as bool? ?? false,
      isPriority: json['priority'] as bool? ?? false,
      wallClock: DateTime.parse(json['wallclock'] as String),
      teamId: teamId,
      participants: participants,
      fieldPositionX: json['fieldPositionX'] as double?,
      fieldPositionY: json['fieldPositionY'] as double?,
    );
  }

  static List<MatchEvent> fromJsonList(
    Map<String, dynamic> json, {
    required (String away, String home) teams,
  }) {
    final events = <MatchEvent>[];
    if (json.containsKey('items') && json['items'] is List) {
      for (final item in json['items']) {
        events.add(MatchEvent.fromJson(item, teams: teams));
      }
    }
    return events;
  }
}

class MatchEventParticipant extends Equatable {
  final String jersey;
  final String athleteId;
  final String teamId;
  final String? positionId;
  final String? participantType;

  const MatchEventParticipant({
    required this.jersey,
    required this.athleteId,
    required this.teamId,
    this.positionId,
    this.participantType,
  });

  @override
  List<Object?> get props => [
    jersey,
    athleteId,
    teamId,
    positionId,
    participantType,
  ];

  factory MatchEventParticipant.fromJson(Map<String, dynamic> json) {
    // Extraire l'ID de l'athlète
    String athleteId = '';
    if (json.containsKey('athlete') && json['athlete'] != null) {
      final athleteRef = json['athlete']['\$ref'] as String;
      final parts = athleteRef.split('/');
      athleteId = parts.isNotEmpty ? parts.last : '';
    }

    // Extraire l'ID de l'équipe
    String teamId = '';
    if (json.containsKey('team') && json['team'] != null) {
      final teamRef = json['team']['\$ref'] as String;
      final parts = teamRef.split('/');
      teamId = parts.isNotEmpty ? parts.last : '';
    }

    // Extraire l'ID de la position
    String? positionId;
    if (json.containsKey('position') && json['position'] != null) {
      final positionRef = json['position']['\$ref'] as String;
      final parts = positionRef.split('/');
      positionId = parts.isNotEmpty ? parts.last : null;
    }

    return MatchEventParticipant(
      jersey: json['jersey'] as String? ?? '',
      athleteId: athleteId,
      teamId: teamId,
      positionId: positionId,
      participantType: json['type'] as String?,
    );
  }
}
