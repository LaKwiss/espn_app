import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TimeDisplay extends StatelessWidget {
  const TimeDisplay({super.key, required this.time});

  final String time;

  @override
  Widget build(BuildContext context) {
    final timeParts = time.split(':');
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '${timeParts[0]}:',
          style: GoogleFonts.blackOpsOne(fontSize: 60, color: Colors.black),
        ),
        Text(
          timeParts[1],
          style: GoogleFonts.blackOpsOne(
            fontSize: 60,
            color: const Color(0xFF5A7DF3),
          ),
        ),
      ],
    );
  }
}
