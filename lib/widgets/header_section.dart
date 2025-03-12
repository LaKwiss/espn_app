import 'package:espn_app/class/event.dart';
import 'package:espn_app/class/team.dart';
import 'package:espn_app/widgets/widgets.dart';

class HeaderSection extends StatelessWidget {
  const HeaderSection({super.key, required this.event});

  final Event event;

  @override
  Widget build(BuildContext context) {
    final parts = event.name.split(" at ");
    final awayTeamName = parts.isNotEmpty ? parts.first.trim() : "Away Team";
    final homeTeamName = parts.length > 1 ? parts.last.trim() : "Home Team";

    final awayTeam = Team(
      id: event.idTeam.$1,
      name: awayTeamName,
      shortName: awayTeamName,
    );

    final homeTeam = Team(
      id: event.idTeam.$2,
      name: homeTeamName,
      shortName: homeTeamName,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: RichText(
        text: TextSpan(
          style: GoogleFonts.blackOpsOne(
            fontSize: 44,
            color: Colors.black,
            height: 1.1,
          ),
          children: [
            TextSpan(text: '${awayTeam.name}\n'),
            TextSpan(
              text: 'AT',
              style: GoogleFonts.blackOpsOne(
                fontSize: 44,
                color: Colors.white.withValues(alpha: 178),
              ),
            ),
            TextSpan(text: '\n${homeTeam.name}\n'),
            TextSpan(
              text: 'FIRST LEG',
              style: GoogleFonts.blackOpsOne(
                fontSize: 44,
                color: Colors.white.withValues(alpha: 178),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
