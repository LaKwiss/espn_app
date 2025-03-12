import 'dart:async';
import 'package:espn_app/models/event.dart';
import 'package:espn_app/providers/provider_factory.dart';
import 'package:espn_app/repositories/event_repository/i_event_repository.dart';
import 'package:riverpod/riverpod.dart';

class LeagueAsyncNotifier extends AsyncNotifier<List<Event>> {
  late final IEventRepository _repository;

  @override
  FutureOr<List<Event>> build() async {
    _repository = ref.read(eventRepositoryProvider);
    state = const AsyncLoading();
    try {
      List<Event> events = await _repository.fetchEventsFromLeague('ger.1');
      state = AsyncData(events);
      return events;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return [];
    }
  }

  void fetchEvents(String league) {
    state = const AsyncLoading();
    _repository
        .fetchEventsFromLeague(league)
        .then((events) {
          state = AsyncData(events);
        })
        .catchError((error, stackTrace) {
          state = AsyncError(error, stackTrace);
        });
  }

  Future<String> getLeagueName(String leagueName) async {
    return _repository.fetchLeagueName(leagueName);
  }
}

final leagueAsyncProvider =
    AsyncNotifierProvider<LeagueAsyncNotifier, List<Event>>(() {
      return LeagueAsyncNotifier();
    });
