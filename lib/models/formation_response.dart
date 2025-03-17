// lib/models/formation_response.dart
import 'package:equatable/equatable.dart';

/// Modèle pour la réponse de formation d'équipe
class FormationResponse extends Equatable {
  final String formationName;
  final List<PlayerEntry> players;

  const FormationResponse({required this.formationName, required this.players});

  factory FormationResponse.fromJson(Map<String, dynamic> json) {
    // Extraire la formation
    final formation =
        json['formation'] != null
            ? json['formation']['name'] ?? 'Unknown'
            : 'Unknown';

    // Extraire les joueurs
    final List<PlayerEntry> players = [];
    if (json['entries'] != null && json['entries'] is List) {
      for (var entry in json['entries']) {
        players.add(PlayerEntry.fromJson(entry));
      }
    }

    return FormationResponse(formationName: formation, players: players);
  }

  // Méthode utilitaire pour obtenir uniquement les titulaires
  List<PlayerEntry> get starters {
    return players.where((player) => player.isStarter).toList();
  }

  // Méthode utilitaire pour obtenir uniquement les remplaçants
  List<PlayerEntry> get substitutes {
    return players.where((player) => !player.isStarter).toList();
  }

  // Méthode utilitaire pour obtenir les changements effectués
  List<Substitution> get substitutions {
    final subs = <Substitution>[];

    // Trouver les joueurs qui sont sortis
    for (var player in players) {
      if (player.subbedOut) {
        // Trouver le joueur entrant correspondant
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

/// Modèle pour un joueur dans la formation
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
  athleteRef; // Référence à l'API pour récupérer les détails du joueur
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
    // Extraire le moment de la substitution
    String subMinute = '';
    if (json['subbedOut'] != null &&
        json['subbedOut']['didSub'] == true &&
        json['subbedOut']['clock'] != null) {
      subMinute = json['subbedOut']['clock']['displayValue'] ?? '';
    }

    // Extraire l'ID du remplaçant
    int? replacementId;
    if (json['subbedOut'] != null &&
        json['subbedOut']['didSub'] == true &&
        json['subbedOut']['replacementAthlete'] != null) {
      final refString =
          json['subbedOut']['replacementAthlete']['\$ref'] as String? ?? '';
      replacementId = _extractIdFromRef(refString);
    }

    // Extraire l'URL de référence du joueur
    String athleteRef = '';
    if (json['athlete'] != null && json['athlete']['\$ref'] != null) {
      athleteRef = json['athlete']['\$ref'] as String? ?? '';
    }

    // Vérifier les cartons
    bool hasYellowCard = false;
    bool hasRedCard = false;

    // Logique pour extraire les cartons si disponible dans la réponse JSON
    // Cette partie peut être ajustée en fonction de la structure réelle des données

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

  // Méthode pour créer un objet vide
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

  // Fonction utilitaire pour extraire l'ID du joueur depuis l'URL de référence
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

/// Version enrichie du modèle PlayerEntry avec plus d'informations
class EnrichedPlayerEntry extends PlayerEntry {
  final String displayName;
  final String firstName;
  final String lastName;
  final String positionName;
  final String positionAbbreviation;
  final double x;
  final double y;

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
    required this.x,
    required this.y,
  });

  /// Crée un EnrichedPlayerEntry à partir d'un PlayerEntry de base
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
      x: 0.5, // Valeur par défaut au centre
      y: 0.5, // Valeur par défaut au centre
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
    x,
    y,
  ];
}

/// Modèle pour représenter une substitution
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
