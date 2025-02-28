import 'package:flutter_riverpod/flutter_riverpod.dart';

class SelectedLeagueNotifier extends StateNotifier<String> {
  // Initialize with empty string
  SelectedLeagueNotifier() : super('');

  void selectLeague(String league) {
    if (state != league) {
      state = league;
    }
  }
}

final selectedLeagueProvider =
    StateNotifierProvider<SelectedLeagueNotifier, String>((ref) {
      return SelectedLeagueNotifier();
    });
