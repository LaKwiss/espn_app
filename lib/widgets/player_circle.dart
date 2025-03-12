import 'package:espn_app/class/athlete.dart';
import 'package:espn_app/widgets/widgets.dart';

class PlayerCircle extends StatelessWidget {
  const PlayerCircle({
    super.key,
    required List<Athlete> players,
    required this.playerIndex,
    required this.position,
  }) : _players = players;

  final List<Athlete> _players;
  final int playerIndex;
  final String position;

  @override
  Widget build(BuildContext context) {
    final player = playerIndex < _players.length ? _players[playerIndex] : null;
    final playerName = player?.fullName.split(' ').last ?? 'Player';

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
  }
}
