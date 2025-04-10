import 'package:flutter/material.dart';

class SoccerFieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      paint,
    );

    canvas.drawCircle(Offset(size.width / 2, size.height / 2), 30, paint);

    final penaltyAreaWidth = size.width * 0.6;
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

    canvas.drawRect(
      Rect.fromLTWH(
        (size.width - penaltyAreaWidth) / 2,
        size.height - penaltyAreaHeight,
        penaltyAreaWidth,
        penaltyAreaHeight,
      ),
      paint,
    );

    final goalAreaWidth = size.width * 0.2;
    final goalAreaHeight = size.height * 0.1;

    canvas.drawRect(
      Rect.fromLTWH(
        (size.width - goalAreaWidth) / 2,
        0,
        goalAreaWidth,
        goalAreaHeight,
      ),
      paint,
    );

    canvas.drawRect(
      Rect.fromLTWH(
        (size.width - goalAreaWidth) / 2,
        size.height - goalAreaHeight,
        goalAreaWidth,
        goalAreaHeight,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
