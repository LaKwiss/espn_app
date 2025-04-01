import 'package:espn_app/widgets/widgets.dart';

class LeagueItem {
  static Widget bundesliga({VoidCallback? onTap}) => LeagueBadge(
    leagueName: 'Bundesliga',
    backgroundColor: Color(0xFFD5262F),
    font: GoogleFonts.robotoCondensed(fontWeight: FontWeight.bold),
    onTap: onTap,
  );

  static Widget laLiga({VoidCallback? onTap}) => LeagueBadge(
    leagueName: 'LaLiga',
    backgroundColor: Color(0xFFE50062),
    font: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
    onTap: onTap,
  );

  static Widget ligue1({VoidCallback? onTap}) => LeagueBadge(
    leagueName: 'Ligue 1',
    backgroundColor: Color(0xFF091F92),
    font: GoogleFonts.oswald(fontWeight: FontWeight.bold),
    onTap: onTap,
  );

  static Widget premierLeague({VoidCallback? onTap}) => LeagueBadge(
    leagueName: 'Premier League',
    backgroundColor: Color(0xFF37003C),
    font: GoogleFonts.lora(fontWeight: FontWeight.bold),
    onTap: onTap,
  );

  static Widget serieA({VoidCallback? onTap}) => LeagueBadge(
    leagueName: 'Serie A',
    backgroundColor: Color(0xFF127DC5),
    font: GoogleFonts.rubik(fontWeight: FontWeight.bold),
    onTap: onTap,
  );

  static Widget europaLeague({VoidCallback? onTap}) => LeagueBadge(
    leagueName: 'Europa League',
    backgroundColor: Color(0xFFEF7C00),
    font: GoogleFonts.bebasNeue(fontWeight: FontWeight.bold),
    onTap: onTap,
  );

  static Widget championsLeague({VoidCallback? onTap}) => LeagueBadge(
    leagueName: 'Champions League',
    backgroundColor: Color(0xFF002F6C),
    font: GoogleFonts.raleway(fontWeight: FontWeight.bold),
    onTap: onTap,
  );

  static Widget defaultBadge({
    required String leagueName,
    Color backgroundColor = Colors.grey,
    Color foregroundColor = Colors.white,
    TextStyle? font,
    VoidCallback? onTap,
  }) {
    return LeagueBadge(
      leagueName: leagueName,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      font: font ?? GoogleFonts.roboto(fontWeight: FontWeight.bold),
      onTap: onTap,
    );
  }
}

class LeagueBadge extends StatelessWidget {
  final String leagueName;
  final Color backgroundColor;
  final Color foregroundColor;
  final TextStyle font;
  final VoidCallback? onTap;

  const LeagueBadge({
    super.key,
    required this.leagueName,
    this.backgroundColor = Colors.grey,
    this.foregroundColor = Colors.white,
    required this.font,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 140,
        height: 40,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5.0),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                leagueName,
                style: font.copyWith(color: foregroundColor, fontSize: 20),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
