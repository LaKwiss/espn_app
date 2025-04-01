import 'package:flutter/material.dart';

class SoccerField extends StatelessWidget {
  final Widget? child;

  const SoccerField({super.key, this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.green[800],
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: AspectRatio(
        aspectRatio: 1 / 2,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Lignes du terrain
            CustomPaint(size: Size.infinite, painter: SoccerFieldPainter()),
            // Contenu enfant (joueurs, etc.)
            if (child != null) child!,
          ],
        ),
      ),
    );
  }
}

class SoccerFieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;

    // Ligne médiane
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      paint,
    );

    // Rond central
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.height / 6,
      paint,
    );

    // Surface de réparation haut
    final penaltyAreaWidth = size.width * 0.5;
    final penaltyAreaHeight = size.height * 0.2;
    canvas.drawRect(
      Rect.fromLTWH(
        (size.width - penaltyAreaWidth) / 2,
        0,
        penaltyAreaWidth,
        penaltyAreaHeight,
      ),
      paint,
    );

    // Surface de réparation bas
    canvas.drawRect(
      Rect.fromLTWH(
        (size.width - penaltyAreaWidth) / 2,
        size.height - penaltyAreaHeight,
        penaltyAreaWidth,
        penaltyAreaHeight,
      ),
      paint,
    );

    // Surface de but haut
    final goalAreaWidth = size.width * 0.25;
    final goalAreaHeight = size.height * 0.08;
    canvas.drawRect(
      Rect.fromLTWH(
        (size.width - goalAreaWidth) / 2,
        0,
        goalAreaWidth,
        goalAreaHeight,
      ),
      paint,
    );

    // Surface de but bas
    canvas.drawRect(
      Rect.fromLTWH(
        (size.width - goalAreaWidth) / 2,
        size.height - goalAreaHeight,
        goalAreaWidth,
        goalAreaHeight,
      ),
      paint,
    );

    // Point central
    final paintFill =
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(size.width / 2, size.height / 2), 4, paintFill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
