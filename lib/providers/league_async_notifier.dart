import 'dart:async';

import 'package:espn_app/class/event.dart';
import 'package:espn_app/repositories/event_repository.dart';
import 'package:riverpod/riverpod.dart';

class LeagueAsyncNotifier extends AsyncNotifier<List<Event>> {
  @override
  FutureOr<List<Event>> build() async {
    state = AsyncLoading();
    List<Event> events = await EventRepository.fetchEventsFromLeague('ger.1');
    state = AsyncData(events);
    return events;
  }

  void fetchEvents(String league) {
    state = AsyncLoading();
    EventRepository.fetchEventsFromLeague(league)
        .then((events) {
          state = AsyncData(events);
        })
        .catchError((error, stackTrace) {
          state = AsyncError(error, stackTrace);
        });
  }

  getLeagueName(String leagueName) async {
    return EventRepository.fetchLeagueName(leagueName);
  }
}

final leagueAsyncProvider =
    AsyncNotifierProvider<LeagueAsyncNotifier, List<Event>>(() {
      return LeagueAsyncNotifier();
    });
