// lib/repositories/formation_repository/i_formation_repository.dart
import 'package:espn_app/models/formation_response.dart';

abstract class IFormationRepository {
  Future<FormationResponse> getTeamFormation({
    required String matchId,
    required String teamId,
    required String leagueId,
  });

  Future<List<EnrichedPlayerEntry>> enrichPlayersData(
    List<PlayerEntry> players,
  );
}
