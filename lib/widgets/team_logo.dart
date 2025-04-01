import 'package:flutter/material.dart';
import 'package:espn_app/models/team.dart';

class TeamLogoWidget extends StatelessWidget {
  final Team team;
  final double radius;

  const TeamLogoWidget({super.key, required this.team, this.radius = 30});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CircleAvatar(
          radius: radius,
          backgroundColor: Colors.transparent,
          backgroundImage: NetworkImage(
            'https://a.espncdn.com/i/teamlogos/soccer/500/${team.id}.png',
          ),
        ),
      ],
    );
  }
}
