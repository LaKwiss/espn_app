import 'dart:async';
import 'dart:developer' as dev;
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

  @override
  String toString() =>
      'MatchParams(matchId: $matchId, leagueId: $leagueId, isFinished: $isFinished)';
}

/// Un provider "family" qui émet un Stream:List:MatchEvent.
final matchEventsStreamProvider = StreamProvider.autoDispose.family<
  List<MatchEvent>,
  MatchParams
>((ref, params) {
  dev.log('Creating match events stream for: $params');

  // Crée un contrôleur de stream "broadcast" pour que plusieurs widgets puissent s'abonner
  final controller = StreamController<List<MatchEvent>>.broadcast();

  // Cette variable sera utilisée pour vérifier si le stream est toujours actif
  // avant d'ajouter des événements
  bool isActive = true;
  Timer? timer;

  // Fonction pour charger les événements depuis le repository
  Future<void> loadEvents() async {
    // Vérifie si le stream est toujours actif avant même de commencer
    if (!isActive) {
      dev.log('Stream no longer active, skipping loadEvents()');
      return;
    }

    dev.log('Loading events for match ${params.matchId}');
    try {
      // Récupération des événements
      final events = await MatchEventRepository.fetchMatchEvents(
        matchId: params.matchId,
        leagueId: params.leagueId,
      );

      // Vérifie à nouveau si le stream est toujours actif après l'opération asynchrone
      if (!isActive) {
        dev.log('Stream was closed during fetchMatchEvents, not adding events');
        return;
      }

      if (events.isEmpty) {
        dev.log('No events found for match ${params.matchId}');
      } else {
        dev.log('Loaded ${events.length} events for match ${params.matchId}');
        dev.log(
          'First event: ${events.first.type.name}, team: ${events.first.teamId}',
        );
      }

      // Ajout des événements au stream seulement si le controller est toujours ouvert
      if (isActive && !controller.isClosed) {
        controller.add(events);
      } else {
        dev.log('Stream controller is closed, cannot add events');
      }
    } catch (error, stackTrace) {
      dev.log('Error loading match events: $error');
      dev.log('Stack trace: $stackTrace');

      // Vérifie si le controller est toujours ouvert avant d'ajouter une liste vide
      if (isActive && !controller.isClosed) {
        // Add empty list instead of error to avoid breaking the UI
        controller.add([]);
      }
    }
  }

  // Charge une première fois immédiatement
  loadEvents();

  // Si le match n'est pas terminé, on programme un rafraîchissement régulier
  if (!params.isFinished) {
    timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (isActive) {
        dev.log('Refreshing match events');
        loadEvents();
      }
    });
  }

  // Quand on "dispose" le provider (plus personne n'écoute), on arrête tout
  ref.onDispose(() {
    dev.log('Disposing match events stream');
    // Marque d'abord le stream comme inactif pour éviter les nouveaux ajouts
    isActive = false;
    // Puis annule le timer et ferme le controller
    timer?.cancel();

    // Vérifie si le controller n'est pas déjà fermé avant de le fermer
    if (!controller.isClosed) {
      controller.close();
    }
  });

  return controller.stream;
});
