// lib/providers/formation_async_notifier.dart
import 'dart:async';
import 'package:espn_app/models/formation_response.dart';
import 'package:espn_app/providers/provider_factory.dart';
import 'package:espn_app/repositories/formation_repository/i_formation_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// État pour gérer les données de formation
class FormationState {
  final Map<String, FormationResponse> formationCache;
  final Map<String, List<EnrichedPlayerEntry>> enrichedPlayersCache;

  const FormationState({
    this.formationCache = const {},
    this.enrichedPlayersCache = const {},
  });
}

/// AsyncNotifier pour les formations d'équipe
class FormationAsyncNotifier extends AsyncNotifier<FormationState> {
  late final IFormationRepository _repository;

  @override
  FutureOr<FormationState> build() {
    _repository = ref.read(formationRepositoryProvider);
    return const FormationState();
  }

  /// Récupère la formation d'une équipe pour un match spécifique
  Future<FormationResponse> fetchFormation({
    required String matchId,
    required String teamId,
    required String leagueId,
  }) async {
    state = const AsyncValue.loading();

    try {
      // Clé de cache
      final cacheKey = '$matchId-$teamId';

      // Vérifier si la formation est déjà en cache
      if (state.value != null &&
          state.value!.formationCache.containsKey(cacheKey)) {
        state = AsyncValue.data(state.value!);
        return state.value!.formationCache[cacheKey]!;
      }

      // Sinon, récupérer depuis le repository
      final formation = await _repository.getTeamFormation(
        matchId: matchId,
        teamId: teamId,
        leagueId: leagueId,
      );

      // Mettre à jour le cache
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
      // Retourner une formation vide en cas d'erreur
      return FormationResponse.fromJson({
        'formation': {'name': 'Unknown'},
        'entries': [],
      });
    }
  }

  /// Récupère les données de joueurs enrichies
  Future<List<EnrichedPlayerEntry>> fetchEnrichedPlayers({
    required String matchId,
    required String teamId,
    required String leagueId,
    bool forceRefresh = false,
  }) async {
    state = const AsyncValue.loading();

    try {
      // Clé de cache
      final cacheKey = '$matchId-$teamId';

      // Vérifier si les données enrichies sont déjà en cache et qu'on ne force pas le rafraîchissement
      if (!forceRefresh &&
          state.value != null &&
          state.value!.enrichedPlayersCache.containsKey(cacheKey)) {
        state = AsyncValue.data(state.value!);
        return state.value!.enrichedPlayersCache[cacheKey]!;
      }

      // Récupérer d'abord la formation de base
      final formation = await fetchFormation(
        matchId: matchId,
        teamId: teamId,
        leagueId: leagueId,
      );

      // Ensuite enrichir les données des joueurs
      final enrichedPlayers = await _repository.enrichPlayersData(
        formation.players,
      );

      // Mettre à jour le cache
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

  /// Récupère les formations des deux équipes d'un match
  Future<(FormationResponse, FormationResponse)> fetchMatchFormations({
    required String matchId,
    required String homeTeamId,
    required String awayTeamId,
    required String leagueId,
  }) async {
    // Récupérer les formations en parallèle
    final results = await Future.wait([
      fetchFormation(matchId: matchId, teamId: homeTeamId, leagueId: leagueId),
      fetchFormation(matchId: matchId, teamId: awayTeamId, leagueId: leagueId),
    ]);

    return (results[0], results[1]);
  }
}

// Provider pour accéder au notifier de formation
final formationAsyncProvider =
    AsyncNotifierProvider<FormationAsyncNotifier, FormationState>(
      () => FormationAsyncNotifier(),
    );
