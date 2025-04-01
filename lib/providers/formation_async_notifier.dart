import 'dart:async';
import 'package:espn_app/models/formation_response.dart';
import 'package:espn_app/providers/provider_factory.dart';
import 'package:espn_app/repositories/formation_repository/i_formation_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FormationState {
  final Map<String, FormationResponse> formationCache;
  final Map<String, List<EnrichedPlayerEntry>> enrichedPlayersCache;

  const FormationState({
    this.formationCache = const {},
    this.enrichedPlayersCache = const {},
  });
}

class FormationAsyncNotifier extends AsyncNotifier<FormationState> {
  late final IFormationRepository _repository;

  @override
  FutureOr<FormationState> build() {
    _repository = ref.read(formationRepositoryProvider);
    return const FormationState();
  }

  Future<FormationResponse> fetchFormation({
    required String matchId,
    required String teamId,
    required String leagueId,
  }) async {
    state = const AsyncValue.loading();

    try {
      final cacheKey = '$matchId-$teamId';

      if (state.value != null &&
          state.value!.formationCache.containsKey(cacheKey)) {
        state = AsyncValue.data(state.value!);
        return state.value!.formationCache[cacheKey]!;
      }

      final formation = await _repository.getTeamFormation(
        matchId: matchId,
        teamId: teamId,
        leagueId: leagueId,
      );

      final updatedCache = {...?state.value?.formationCache};
      updatedCache[cacheKey] = formation;

      state = AsyncValue.data(
        FormationState(
          formationCache: updatedCache,
          enrichedPlayersCache: state.value?.enrichedPlayersCache ?? {},
        ),
      );

      return formation;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return FormationResponse.fromJson({
        'formation': {'name': 'Unknown'},
        'entries': [],
      });
    }
  }

  Future<List<EnrichedPlayerEntry>> fetchEnrichedPlayers({
    required String matchId,
    required String teamId,
    required String leagueId,
    bool forceRefresh = false,
  }) async {
    state = const AsyncValue.loading();

    try {
      final cacheKey = '$matchId-$teamId';

      if (!forceRefresh &&
          state.value != null &&
          state.value!.enrichedPlayersCache.containsKey(cacheKey)) {
        state = AsyncValue.data(state.value!);
        return state.value!.enrichedPlayersCache[cacheKey]!;
      }

      final formation = await fetchFormation(
        matchId: matchId,
        teamId: teamId,
        leagueId: leagueId,
      );

      final enrichedPlayers = await _repository.enrichPlayersData(
        formation.players,
      );

      final updatedCache = {...?state.value?.enrichedPlayersCache};
      updatedCache[cacheKey] = enrichedPlayers;

      state = AsyncValue.data(
        FormationState(
          formationCache: state.value?.formationCache ?? {},
          enrichedPlayersCache: updatedCache,
        ),
      );

      return enrichedPlayers;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return [];
    }
  }

  Future<(FormationResponse, FormationResponse)> fetchMatchFormations({
    required String matchId,
    required String homeTeamId,
    required String awayTeamId,
    required String leagueId,
  }) async {
    final results = await Future.wait([
      fetchFormation(matchId: matchId, teamId: homeTeamId, leagueId: leagueId),
      fetchFormation(matchId: matchId, teamId: awayTeamId, leagueId: leagueId),
    ]);

    return (results[0], results[1]);
  }
}

final formationAsyncProvider =
    AsyncNotifierProvider<FormationAsyncNotifier, FormationState>(
      () => FormationAsyncNotifier(),
    );
