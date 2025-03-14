import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LastMatches extends StatelessWidget {
  final String formString;

  const LastMatches({super.key, required this.formString});

  @override
  Widget build(BuildContext context) {
    // Convert form string to list (e.g., "WDWLW" -> ["W", "D", "W", "L", "W"])
    final formList = formString.split('');

    // Map result codes to colors
    final colors = {'W': Colors.green, 'D': Colors.orange, 'L': Colors.red};

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'LAST 5 MATCHES',
              style: GoogleFonts.blackOpsOne(fontSize: 18, color: Colors.black),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children:
                  formList.take(5).map((result) {
                    return Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colors[result] ?? Colors.grey,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          result,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem('W', 'Win', Colors.green),
                const SizedBox(width: 16),
                _buildLegendItem('D', 'Draw', Colors.orange),
                const SizedBox(width: 16),
                _buildLegendItem('L', 'Loss', Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String letter, String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 4),
        Text('$letter = $label', style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
