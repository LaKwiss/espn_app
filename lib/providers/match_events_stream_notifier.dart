import 'dart:async';
import 'package:espn_app/class/match_event.dart';
import 'package:espn_app/repositories/match_event_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Regroupe les paramètres pour charger les événements d'un match
class MatchParams {
  final String matchId;
  final String leagueId;
  final bool isFinished; // indique si le match est terminé ou non

  MatchParams({
    required this.matchId,
    required this.leagueId,
    this.isFinished = false,
  });
}

/// Un provider "family" qui émet un Stream:List:MatchEvent.
final matchEventsStreamProvider = StreamProvider.autoDispose.family<
  List<MatchEvent>,
  MatchParams
>((ref, params) {
  // Crée un contrôleur de stream "broadcast" pour que plusieurs widgets puissent s'abonner
  final controller = StreamController<List<MatchEvent>>.broadcast();

  bool isActive = true; // Indique si on écoute toujours le provider
  Timer? timer;

  // Fonction pour charger les événements depuis le repository
  Future<void> loadEvents() async {
    try {
      final events = await MatchEventRepository.fetchMatchEvents(
        matchId: params.matchId,
        leagueId: params.leagueId,
      );
      if (isActive) {
        controller.add(events);
      }
    } catch (error, stackTrace) {
      if (isActive) {
        controller.addError(error, stackTrace);
      }
    }
  }

  // Charge une première fois immédiatement
  loadEvents();

  // Si le match n'est pas terminé, on programme un rafraîchissement régulier
  if (!params.isFinished) {
    timer = Timer.periodic(const Duration(seconds: 2), (_) {
      loadEvents();
    });
  }

  // Quand on "dispose" le provider (plus personne n'écoute), on arrête tout
  ref.onDispose(() {
    isActive = false;
    timer?.cancel();
    controller.close();
  });

  return controller.stream;
});
