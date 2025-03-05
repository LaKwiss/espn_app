import 'package:espn_app/repositories/league_picture_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SelectedLeagueNotifier
    extends StateNotifier<(String league, String code)> {
  // Initialize with empty string
  SelectedLeagueNotifier() : super(('Bundesliga', 'ger.1'));

  void selectLeague(String league) {
    state = (league, state.$2);
  }

  void selectCode(String code) {
    state = (state.$1, code);
  }

  Future<String> getUrlByLeagueCode(String $2) async {
    final String code = state.$2;
    return await LeaguePictureRepository.getUrlByLeagueCode(code);
  }
}

final selectedLeagueProvider =
    StateNotifierProvider<SelectedLeagueNotifier, (String, String)>((ref) {
      return SelectedLeagueNotifier();
    });
