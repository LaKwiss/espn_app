import 'package:espn_app/models/athlete.dart';

class SubstituteAthlete {
  final Athlete athlete;
  bool hasEntered;

  SubstituteAthlete({required this.athlete, this.hasEntered = false});

  bool get hasYellowCard => athlete.stats.yellowCards > 0;
  bool get hasRedCard => athlete.stats.redCards > 0;

  String get fullName => athlete.fullName;
  int get id => athlete.id;
}
