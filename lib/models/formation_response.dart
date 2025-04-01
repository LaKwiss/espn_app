import 'package:equatable/equatable.dart';

class FormationResponse extends Equatable {
  final String formationName;
  final List<PlayerEntry> players;

  const FormationResponse({required this.formationName, required this.players});

  factory FormationResponse.fromJson(Map<String, dynamic> json) {
    final formation =
        json['formation'] != null
            ? json['formation']['name'] ?? 'Unknown'
            : 'Unknown';

    final List<PlayerEntry> players = [];
    if (json['entries'] != null && json['entries'] is List) {
      for (var entry in json['entries']) {
        players.add(PlayerEntry.fromJson(entry));
      }
    }

    return FormationResponse(formationName: formation, players: players);
  }

  List<PlayerEntry> get starters {
    return players.where((player) => player.isStarter).toList();
  }

  List<PlayerEntry> get substitutes {
    return players.where((player) => !player.isStarter).toList();
  }

  List<Substitution> get substitutions {
    final subs = <Substitution>[];

    for (var player in players) {
      if (player.subbedOut) {
        final replacement = players.firstWhere(
          (p) => p.playerId == player.replacementId,
          orElse: () => PlayerEntry.empty(),
        );

        if (replacement.playerId != 0) {
          subs.add(
            Substitution(
              playerOut: player,
              playerIn: replacement,
              minute: player.subMinute,
            ),
          );
        }
      }
    }

    return subs;
  }

  @override
  List<Object?> get props => [formationName, players];
}

class PlayerEntry extends Equatable {
  final int playerId;
  final String jerseyNumber;
  final bool isStarter;
  final int formationPlace;
  final bool subbedIn;
  final bool subbedOut;
  final int? replacementId;
  final String subMinute;
  final String
  athleteRef;
  final bool hasYellowCard;
  final bool hasRedCard;

  const PlayerEntry({
    required this.playerId,
    required this.jerseyNumber,
    required this.isStarter,
    required this.formationPlace,
    required this.subbedIn,
    required this.subbedOut,
    this.replacementId,
    required this.subMinute,
    required this.athleteRef,
    this.hasYellowCard = false,
    this.hasRedCard = false,
  });

  factory PlayerEntry.fromJson(Map<String, dynamic> json) {
    String subMinute = '';
    if (json['subbedOut'] != null &&
        json['subbedOut']['didSub'] == true &&
        json['subbedOut']['clock'] != null) {
      subMinute = json['subbedOut']['clock']['displayValue'] ?? '';
    }

    int? replacementId;
    if (json['subbedOut'] != null &&
        json['subbedOut']['didSub'] == true &&
        json['subbedOut']['replacementAthlete'] != null) {
      final refString =
          json['subbedOut']['replacementAthlete']['\$ref'] as String? ?? '';
      replacementId = _extractIdFromRef(refString);
    }

    String athleteRef = '';
    if (json['athlete'] != null && json['athlete']['\$ref'] != null) {
      athleteRef = json['athlete']['\$ref'] as String? ?? '';
    }

    bool hasYellowCard = false;
    bool hasRedCard = false;

    return PlayerEntry(
      playerId: json['playerId'] ?? 0,
      jerseyNumber: json['jersey'] ?? '',
      isStarter: json['starter'] ?? false,
      formationPlace:
          json['formationPlace'] != null
              ? int.parse(json['formationPlace'].toString())
              : 0,
      subbedIn:
          json['subbedIn'] != null
              ? json['subbedIn']['didSub'] ?? false
              : false,
      subbedOut:
          json['subbedOut'] != null
              ? json['subbedOut']['didSub'] ?? false
              : false,
      replacementId: replacementId,
      subMinute: subMinute,
      athleteRef: athleteRef,
      hasYellowCard: hasYellowCard,
      hasRedCard: hasRedCard,
    );
  }

  factory PlayerEntry.empty() {
    return const PlayerEntry(
      playerId: 0,
      jerseyNumber: '',
      isStarter: false,
      formationPlace: 0,
      subbedIn: false,
      subbedOut: false,
      replacementId: null,
      subMinute: '',
      athleteRef: '',
    );
  }

  @override
  List<Object?> get props => [
    playerId,
    jerseyNumber,
    isStarter,
    formationPlace,
    subbedIn,
    subbedOut,
    replacementId,
    subMinute,
    athleteRef,
    hasYellowCard,
    hasRedCard,
  ];

  static int? _extractIdFromRef(String ref) {
    if (ref.isEmpty) return null;

    final parts = ref.split('/');
    if (parts.isNotEmpty) {
      final lastPart = parts.last;
      return int.tryParse(lastPart.split('?').first);
    }
    return null;
  }
}

class EnrichedPlayerEntry extends PlayerEntry {
  final String displayName;
  final String firstName;
  final String lastName;
  final String positionName;
  final String positionAbbreviation;

  const EnrichedPlayerEntry({
    required super.playerId,
    required super.jerseyNumber,
    required super.isStarter,
    required super.formationPlace,
    required super.subbedIn,
    required super.subbedOut,
    super.replacementId,
    required super.subMinute,
    required super.athleteRef,
    super.hasYellowCard = false,
    super.hasRedCard = false,
    required this.displayName,
    required this.firstName,
    required this.lastName,
    required this.positionName,
    required this.positionAbbreviation,
  });

  factory EnrichedPlayerEntry.fromPlayerEntry(PlayerEntry player) {
    return EnrichedPlayerEntry(
      playerId: player.playerId,
      jerseyNumber: player.jerseyNumber,
      isStarter: player.isStarter,
      formationPlace: player.formationPlace,
      subbedIn: player.subbedIn,
      subbedOut: player.subbedOut,
      replacementId: player.replacementId,
      subMinute: player.subMinute,
      athleteRef: player.athleteRef,
      hasYellowCard: player.hasYellowCard,
      hasRedCard: player.hasRedCard,
      displayName: 'Player ${player.playerId}',
      firstName: '',
      lastName: 'Player ${player.playerId}',
      positionName: 'Unknown',
      positionAbbreviation: '',
    );
  }

  @override
  List<Object?> get props => [
    ...super.props,
    displayName,
    firstName,
    lastName,
    positionName,
    positionAbbreviation,
  ];
}

class Substitution extends Equatable {
  final PlayerEntry playerOut;
  final PlayerEntry playerIn;
  final String minute;

  const Substitution({
    required this.playerOut,
    required this.playerIn,
    required this.minute,
  });

  @override
  List<Object?> get props => [playerOut, playerIn, minute];
}
