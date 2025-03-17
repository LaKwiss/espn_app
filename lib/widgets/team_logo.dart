import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:espn_app/models/team.dart';

class TeamLogoWidget extends StatelessWidget {
  final Team team;
  final double radius;
  final bool isInteractive;
  final Color? borderColor;

  const TeamLogoWidget({
    super.key,
    required this.team,
    this.radius = 30,
    this.isInteractive = true,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isInteractive ? () => _showTeamDetails(context, team) : null,
      child: Stack(
        children: [
          CircleAvatar(
            radius: radius,
            backgroundColor: Colors.transparent,
            backgroundImage: NetworkImage(
              'https://a.espncdn.com/i/teamlogos/soccer/500/${team.id}.png',
            ),
            onBackgroundImageError: (exception, stackTrace) {
              // Fallback si l'image ne charge pas
            },
          ),
          if (isInteractive && borderColor != null)
            Container(
              width: radius * 2,
              height: radius * 2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: borderColor!, width: 2),
              ),
            ),
          if (isInteractive)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: radius * 0.6,
                height: radius * 0.6,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1),
                ),
                child: Icon(
                  Icons.info_outline,
                  color: Colors.white,
                  size: radius * 0.4,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showTeamDetails(BuildContext context, Team team) {
    log(team.toString());
  }
}
