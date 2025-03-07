import 'package:flutter/material.dart';
import 'package:espn_app/class/team.dart';
import 'package:espn_app/screens/team_detail_screen.dart';

class TeamLogoWidget extends StatelessWidget {
  final Team team;
  final double size;
  final bool showTeamDetailOnTap;
  final bool isHomeTeam; // Identifies if this is the home team

  const TeamLogoWidget({
    super.key,
    required this.team,
    this.size = 48,
    this.showTeamDetailOnTap = true,
    this.isHomeTeam = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: showTeamDetailOnTap ? () => _showTeamDetail(context) : null,
      child: Hero(
        tag: 'team-logo-${team.id}',
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            children: [
              ClipOval(
                child: Image.network(
                  'https://a.espncdn.com/i/teamlogos/soccer/500/${team.id}.png',
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return CircleAvatar(
                      radius: size / 2,
                      backgroundColor: Colors.grey[300],
                      child: Text(
                        team.shortName.isNotEmpty
                            ? team.shortName.substring(0, 1)
                            : '',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: size / 2,
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Pulsating effect when tappable
              if (showTeamDetailOnTap)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color:
                            isHomeTeam
                                ? Colors.blue.withOpacity(0.7)
                                : Colors.red.withOpacity(0.7),
                        width: 2,
                      ),
                    ),
                  ),
                ),
              // Small info indicator
              if (showTeamDetailOnTap)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: size / 4,
                    height: size / 4,
                    decoration: BoxDecoration(
                      color: isHomeTeam ? Colors.blue : Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.info_outline,
                      color: Colors.white,
                      size: size / 6,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTeamDetail(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => TeamDetailScreen(team: team)),
    );
  }
}
