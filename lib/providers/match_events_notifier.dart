import 'dart:developer' as dev;
import 'package:espn_app/models/match_event.dart';
import 'package:espn_app/providers/provider_factory.dart';
import 'package:espn_app/repositories/match_event_repository/i_match_event_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MatchParams &&
          runtimeType == other.runtimeType &&
          matchId == other.matchId &&
          leagueId == other.leagueId;

  @override
  int get hashCode => matchId.hashCode ^ leagueId.hashCode;
}

// AsyncNotifier pour gérer les événements du match
class MatchEventsNotifier extends AsyncNotifier<List<MatchEvent>> {
  MatchParams? _params;
  late final IMatchEventRepository _repository;
  bool _isInitialized = false;

  // Initialiser le notifier avec les paramètres spécifiques
  void initialize(MatchParams params) {
    dev.log('Initializing events notifier with params: $params');
    // Always update parameters and reload
    _params = params;
    _repository = ref.read(matchEventRepositoryProvider);
    // Always load data immediately
    _fetchEvents();
    _isInitialized = true;
  }

  // Récupérer les événements depuis le repository
  Future<void> _fetchEvents() async {
    if (_params == null) {
      dev.log('Cannot fetch events: params are null');
      state = const AsyncValue.data([]);
      return;
    }

    state = const AsyncValue.loading();
    try {
      dev.log('Fetching events for match ${_params!.matchId}');
      final events = await _repository.fetchMatchEvents(
        matchId: _params!.matchId,
        leagueId: _params!.leagueId,
      );

      if (events.isEmpty) {
        dev.log('No events found for match ${_params!.matchId}');
      } else {
        dev.log('Loaded ${events.length} events for match ${_params!.matchId}');
      }

      state = AsyncValue.data(events);
    } catch (error, stackTrace) {
      dev.log('Error loading match events: $error');
      state = AsyncValue.error(error, stackTrace);
    }
  }

  // Rafraîchir les données manuellement
  Future<void> refresh() async {
    dev.log('Manually refreshing events');
    return _fetchEvents();
  }

  @override
  Future<List<MatchEvent>> build() async {
    // Si _params n'est pas encore défini, retourner une liste vide
    if (_params == null) {
      dev.log('Building with empty state: params not set');
      return [];
    }

    // Utiliser _fetchEvents pour charger les données
    await _fetchEvents();

    // Récupérer les données de l'état actuel
    return state.valueOrNull ?? [];
  }
}

// Provider pour accéder au notifier
final matchEventsProvider =
    AsyncNotifierProvider<MatchEventsNotifier, List<MatchEvent>>(
      () => MatchEventsNotifier(),
    );

// Pour utiliser le provider avec des paramètres spécifiques
void initializeMatchEvents(WidgetRef ref, MatchParams params) {
  dev.log('Initializing match events with: $params');
  ref.read(matchEventsProvider.notifier).initialize(params);
}
