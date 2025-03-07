import 'package:flutter/material.dart';
import 'package:espn_app/class/club.dart';
import 'package:espn_app/screens/club_detail_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class ClubInfoWidget extends StatelessWidget {
  final Club club;

  const ClubInfoWidget({super.key, required this.club});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showClubDetail(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.network(
              club.logo,
              height: 24,
              width: 24,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.sports_soccer,
                  color: Colors.white,
                  size: 24,
                );
              },
            ),
            const SizedBox(width: 8),
            Text(
              club.name,
              style: GoogleFonts.roboto(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.info_outline, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }

  void _showClubDetail(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => ClubDetailScreen(club: club)),
    );
  }
}
