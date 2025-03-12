// lib/providers/match_events_notifier.dart
import 'dart:developer' as dev;
import 'package:espn_app/models/match_event.dart';
import 'package:espn_app/providers/provider_factory.dart';
import 'package:espn_app/repositories/match_event_repository/i_match_event_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Classe pour contenir les paramètres du match
class MatchParams {
  final String matchId;
  final String leagueId;
  final bool isFinished;

  MatchParams({
    required this.matchId,
    required this.leagueId,
    this.isFinished = false,
  });

  @override
  String toString() =>
      'MatchParams(matchId: $matchId, leagueId: $leagueId, isFinished: $isFinished)';
}

// AsyncNotifier pour gérer les événements du match
class MatchEventsNotifier extends AsyncNotifier<List<MatchEvent>> {
  late MatchParams _params;
  late final IMatchEventRepository _repository;

  // Initialiser le notifier avec les paramètres spécifiques
  void initialize(MatchParams params) {
    _params = params;
    _repository = ref.read(matchEventRepositoryProvider);
    // Charger les données immédiatement
    _fetchEvents();
  }

  // Récupérer les événements depuis le repository
  Future<void> _fetchEvents() async {
    state = const AsyncValue.loading();
    try {
      dev.log('Fetching events for match ${_params.matchId}');
      final events = await _repository.fetchMatchEvents(
        matchId: _params.matchId,
        leagueId: _params.leagueId,
      );

      if (events.isEmpty) {
        dev.log('No events found for match ${_params.matchId}');
      } else {
        dev.log('Loaded ${events.length} events for match ${_params.matchId}');
      }

      state = AsyncValue.data(events);
    } catch (error, stackTrace) {
      dev.log('Error loading match events: $error');
      state = AsyncValue.error(error, stackTrace);
    }
  }

  // Rafraîchir les données manuellement
  Future<void> refresh() async {
    _fetchEvents();
  }

  @override
  Future<List<MatchEvent>> build() async {
    // Sera remplacé par initialize() quand on l'appelle
    return [];
  }
}

// Provider pour accéder au notifier
final matchEventsProvider =
    AsyncNotifierProvider<MatchEventsNotifier, List<MatchEvent>>(
      () => MatchEventsNotifier(),
    );

// Pour utiliser le provider avec des paramètres spécifiques
void initializeMatchEvents(WidgetRef ref, MatchParams params) {
  ref.read(matchEventsProvider.notifier).initialize(params);
}
