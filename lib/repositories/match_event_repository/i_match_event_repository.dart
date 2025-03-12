import 'package:espn_app/models/match_event.dart';

abstract class IMatchEventRepository {
  Future<List<MatchEvent>> fetchMatchEvents({
    required String matchId,
    required String leagueId,
  });

  Future<List<MatchEvent>> fetchLiveMatchEvents({
    required String matchId,
    required String leagueId,
  });

  Future<(String away, String home)> fetchTeamIds(
    String matchId,
    String leagueId,
  );
}
