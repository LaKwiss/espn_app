import 'package:espn_app/models/substitute_athlete.dart';

class Substitution {
  final SubstituteAthlete playerIn;
  final String playerOutNumber;
  final String playerOutName;
  final String minute;

  const Substitution({
    required this.playerIn,
    required this.playerOutNumber,
    required this.playerOutName,
    required this.minute,
  });
}
