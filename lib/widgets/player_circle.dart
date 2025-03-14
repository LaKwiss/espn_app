// lib/widgets/player_circle.dart
import 'package:espn_app/models/athlete.dart';
import 'package:espn_app/providers/athletes_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class PlayerCircle extends ConsumerWidget {
  final String playerId;
  final String position;
  final String leagueId;

  const PlayerCircle({
    super.key,
    required this.playerId,
    required this.position,
    required this.leagueId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<Athlete>(
      future: ref
          .read(athletesProvider.notifier)
          .getAthleteById(leagueId, playerId),
      builder: (context, snapshot) {
        String playerName = 'Player';

        if (snapshot.hasData && snapshot.data != null) {
          final player = snapshot.data!;
          playerName = player.fullName.split(' ').last;
        }

        return Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(color: Colors.black, width: 2),
              ),
              child: Center(
                child: Text(
                  position,
                  style: GoogleFonts.roboto(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                playerName,
                style: GoogleFonts.roboto(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
