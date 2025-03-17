import 'package:espn_app/models/lineup.dart';

abstract class ILineupRepository {
  Future<Lineup> getTeamLineup(String leagueId, String teamId, String eventId);
}
