// lib/providers/selected_league_notifier.dart
import 'package:espn_app/providers/provider_factory.dart';
import 'package:espn_app/repositories/league_picture_repository/i_league_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SelectedLeagueNotifier
    extends StateNotifier<(String league, String code)> {
  final ILeaguePictureRepository _repository;

  // Initialize with default values and repository
  SelectedLeagueNotifier({required ILeaguePictureRepository repository})
    : _repository = repository,
      super(('Bundesliga', 'ger.1'));

  void selectLeague(String league) {
    state = (league, state.$2);
  }

  void selectCode(String code) {
    state = (state.$1, code);
  }

  Future<String> getUrlByLeagueCode(String code) async {
    return await _repository.getUrlByLeagueCode(code.isEmpty ? state.$2 : code);
  }
}

final selectedLeagueProvider =
    StateNotifierProvider<SelectedLeagueNotifier, (String, String)>((ref) {
      return SelectedLeagueNotifier(
        repository: ref.watch(leaguePictureRepositoryProvider),
      );
    });
