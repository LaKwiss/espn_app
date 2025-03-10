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

  bool isActive = true; // Indique si on écoute toujours le provider
  Timer? timer;

  // Fonction pour charger les événements depuis le repository
  Future<void> loadEvents() async {
    dev.log('Loading events for match ${params.matchId}');
    try {
      // If match is not started, add empty list to simulate "no events yet"
      // Remove this condition to force fetch from API
      // if (!params.isFinished) {
      //   controller.add([]);
      //   return;
      // }

      final events = await MatchEventRepository.fetchMatchEvents(
        matchId: params.matchId,
        leagueId: params.leagueId,
      );

      dev.log('Loaded ${events.length} events for match ${params.matchId}');

      if (events.isEmpty) {
        dev.log('No events found for match ${params.matchId}');
      } else {
        dev.log('Loaded ${events.length} events for match ${params.matchId}');
        dev.log(
          'First event: ${events.first.type.name}, team: ${events.first.teamId}',
        );
      }

      if (isActive) {
        controller.add(events);
      }
    } catch (error, stackTrace) {
      dev.log('Error loading match events: $error');
      dev.log('Stack trace: $stackTrace');
      if (isActive) {
        // Add empty list instead of error to avoid breaking the UI
        // controller.addError(error, stackTrace);
        controller.add([]);
      }
    }
  }

  // Charge une première fois immédiatement
  loadEvents();

  // Si le match n'est pas terminé, on programme un rafraîchissement régulier
  if (!params.isFinished) {
    timer = Timer.periodic(const Duration(seconds: 5), (_) {
      dev.log('Refreshing match events');
      loadEvents();
    });
  }

  // Quand on "dispose" le provider (plus personne n'écoute), on arrête tout
  ref.onDispose(() {
    dev.log('Disposing match events stream');
    isActive = false;
    timer?.cancel();
    controller.close();
  });

  return controller.stream;
});
