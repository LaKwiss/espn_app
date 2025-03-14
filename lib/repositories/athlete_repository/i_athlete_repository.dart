// lib/repositories/athletes_repository/i_athletes_repository.dart
import 'package:espn_app/models/athlete.dart';

abstract class IAthletesRepository {
  Future<List<Athlete>> getTeamAthletes(String leagueId, String teamId);
  Future<Athlete> getAthleteById(String leagueId, String athleteId);
}
