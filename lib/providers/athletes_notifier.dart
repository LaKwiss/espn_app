// lib/providers/athletes_notifier.dart
import 'package:espn_app/models/athlete.dart';
import 'package:espn_app/providers/provider_factory.dart';
import 'package:espn_app/repositories/athlete_repository/i_athlete_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AthletesNotifier extends AsyncNotifier<List<Athlete>> {
  late final IAthletesRepository _repository;

  @override
  Future<List<Athlete>> build() async {
    _repository = ref.read(athletesRepositoryProvider);
    // Retourner une liste vide à l'initialisation
    return [];
  }

  Future<void> fetchTeamAthletes(String leagueId, String teamId) async {
    state = const AsyncLoading();
    try {
      final athletes = await _repository.getTeamAthletes(leagueId, teamId);
      state = AsyncData(athletes);
    } catch (e, stackTrace) {
      state = AsyncError(e, stackTrace);
    }
  }

  Future<Athlete> getAthleteById(String leagueId, String athleteId) async {
    try {
      // Vérifier si l'athlète est déjà dans l'état actuel
      if (state.value != null) {
        final existingAthlete = state.value!.firstWhere(
          (athlete) => athlete.id.toString() == athleteId,
          orElse: () => Athlete.empty(),
        );

        if (existingAthlete.id != 0) {
          return existingAthlete;
        }
      }

      // Sinon, récupérer depuis le repository
      return await _repository.getAthleteById(leagueId, athleteId);
    } catch (e) {
      return Athlete.empty();
    }
  }
}

final athletesProvider = AsyncNotifierProvider<AthletesNotifier, List<Athlete>>(
  () {
    return AthletesNotifier();
  },
);
