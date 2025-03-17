import 'package:flutter/material.dart';
import 'package:espn_app/models/formation_response.dart';
import 'package:google_fonts/google_fonts.dart';

class FormationVisualizer extends StatelessWidget {
  final String formation;
  final List<EnrichedPlayerEntry> players;
  final Color teamColor;
  final String teamName;
  final bool isHomeTeam;
  final Function(EnrichedPlayerEntry)? onPlayerTap;

  const FormationVisualizer({
    super.key,
    required this.formation,
    required this.players,
    required this.teamColor,
    required this.teamName,
    this.isHomeTeam = true,
    this.onPlayerTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            "$teamName - $formation",
            style: GoogleFonts.blackOpsOne(fontSize: 18, color: teamColor),
          ),
        ),
        AspectRatio(
          aspectRatio: 1.5,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.green[800],
              borderRadius: BorderRadius.circular(8),
            ),
            child: _buildFormationLayout(context),
          ),
        ),
      ],
    );
  }

  Widget _buildFormationLayout(BuildContext context) {
    final starters = players.where((p) => p.isStarter).toList();

    if (starters.isEmpty) {
      return const SizedBox();
    }

    final Size size = MediaQuery.of(context).size;

    return Stack(
      children: [
        CustomPaint(size: Size.infinite, painter: SoccerFieldPainter()),
        ...starters.map((player) {
          final position = _calculatePlayerPosition(
            player,
            starters,
            formation,
          );
          return Positioned(
            left: position.$1 * size.width * 0.8,
            top: position.$2 * size.width * 0.5,
            child: _buildPlayerMarker(player, context),
          );
        }),
      ],
    );
  }

  Widget _buildPlayerMarker(EnrichedPlayerEntry player, BuildContext context) {
    return GestureDetector(
      onTap: onPlayerTap != null ? () => onPlayerTap!(player) : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: teamColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Center(
              child: Text(
                player.jerseyNumber,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              _getShortName(player.displayName),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  (double, double) _calculatePlayerPosition(
    EnrichedPlayerEntry player,
    List<EnrichedPlayerEntry> starters,
    String formation,
  ) {
    double x = 0.5, y = 0.5;

    if (player.formationPlace == 1) {
      // Goalkeeper
      y = isHomeTeam ? 0.9 : 0.1;
      x = 0.5;
      return (x, y);
    }

    try {
      final parts = formation.split('-').map(int.parse).toList();
      if (parts.isEmpty) return (x, y);

      final defenders = parts[0];
      final midfielders = parts.length > 1 ? parts[1] : 0;
      final forwards = parts.length > 2 ? parts[2] : 0;

      final defenseEnd = 1 + defenders;
      final midfieldEnd = defenseEnd + midfielders;

      if (player.formationPlace > 1 && player.formationPlace <= defenseEnd) {
        // Defenders
        y = isHomeTeam ? 0.75 : 0.25;
        final position = player.formationPlace - 2;
        final totalInLine = defenders;
        x = _getXPositionInLine(position, totalInLine);
      } else if (player.formationPlace > defenseEnd &&
          player.formationPlace <= midfieldEnd) {
        // Midfielders
        y = 0.5;
        final position = player.formationPlace - defenseEnd - 1;
        final totalInLine = midfielders;
        x = _getXPositionInLine(position, totalInLine);
      } else {
        // Forwards
        y = isHomeTeam ? 0.25 : 0.75;
        final position = player.formationPlace - midfieldEnd - 1;
        final totalInLine = forwards;
        x = _getXPositionInLine(position, totalInLine);
      }
    } catch (e) {
      // Fall back to default position
    }

    return (x, y);
  }

  double _getXPositionInLine(int position, int totalInLine) {
    if (totalInLine <= 1) return 0.5;

    // Calculate distributed positions
    final step = 0.8 / (totalInLine - 1);
    final x = 0.1 + (position * step);
    return x.clamp(0.1, 0.9);
  }

  String _getShortName(String fullName) {
    if (fullName.isEmpty) return '';

    final parts = fullName.split(' ');
    if (parts.length <= 1) return fullName;

    final lastName = parts.last;
    if (lastName.length <= 7) {
      return lastName;
    } else {
      return lastName.substring(0, 5) + '..';
    }
  }
}

class SoccerFieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;

    // Field outline
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Center line
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      paint,
    );

    // Center circle
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.height / 8,
      paint,
    );

    // Top penalty area
    final penaltyWidth = size.width * 0.5;
    final penaltyHeight = size.height * 0.2;
    canvas.drawRect(
      Rect.fromLTWH(
        (size.width - penaltyWidth) / 2,
        0,
        penaltyWidth,
        penaltyHeight,
      ),
      paint,
    );

    // Bottom penalty area
    canvas.drawRect(
      Rect.fromLTWH(
        (size.width - penaltyWidth) / 2,
        size.height - penaltyHeight,
        penaltyWidth,
        penaltyHeight,
      ),
      paint,
    );

    // Center spot
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      3,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
