import 'package:espn_app/widgets/widgets.dart';

class ScoreDisplay extends StatelessWidget {
  const ScoreDisplay({
    super.key,
    required this.homeScore,
    required this.awayScore,
  });

  final int homeScore;
  final int awayScore;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '$homeScore:',
          style: GoogleFonts.blackOpsOne(
            fontSize: 60,
            color: const Color(0xFF5A7DF3),
          ),
        ),
        Text(
          '$awayScore',
          style: GoogleFonts.blackOpsOne(fontSize: 60, color: Colors.black),
        ),
      ],
    );
  }
}
