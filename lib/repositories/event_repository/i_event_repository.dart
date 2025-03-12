import 'package:espn_app/models/event.dart';

abstract class IEventRepository {
  Future<List<Event>> fetchEventsFromLeague(String league);
  Future<String> fetchLeagueName(String leagueName);
  Future<List<Event>> fetchEventsByDate(String league, DateTime date);
}
