// lib/providers/lineup_notifier.dart
import 'package:espn_app/models/lineup.dart';
import 'package:espn_app/providers/provider_factory.dart';
import 'package:espn_app/repositories/lineup_repository/i_lineup_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LineupNotifier extends AsyncNotifier<Lineup> {
  late final ILineupRepository _repository;

  @override
  Future<Lineup> build() async {
    _repository = ref.read(lineupRepositoryProvider);
    // Retour d'une composition vide au départ
    return Lineup.empty();
  }

  Future<void> fetchLineup(
    String leagueId,
    String teamId,
    String eventId,
  ) async {
    state = const AsyncLoading();
    try {
      final lineup = await _repository.getTeamLineup(leagueId, teamId, eventId);
      state = AsyncData(lineup);
    } catch (e, stackTrace) {
      state = AsyncError(e, stackTrace);
    }
  }
}

final lineupProvider = AsyncNotifierProvider<LineupNotifier, Lineup>(() {
  return LineupNotifier();
});
