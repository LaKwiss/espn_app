import 'package:espn_app/class/club.dart';
import 'package:espn_app/screens/club_detail_screen.dart';
import 'package:espn_app/widgets/widgets.dart';

class ClubInfoWidget extends StatelessWidget {
  final Club club;
  final Color? backgroundColor;
  final Color? textColor;

  const ClubInfoWidget({
    super.key,
    required this.club,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showClubDetails(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.black.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.network(
              club.logo,
              height: 24,
              width: 24,
              errorBuilder:
                  (context, error, stackTrace) => Icon(
                    Icons.sports_soccer,
                    color: textColor ?? Colors.white,
                    size: 24,
                  ),
            ),
            const SizedBox(width: 8),
            Text(
              club.name,
              style: GoogleFonts.roboto(
                color: textColor ?? Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.info_outline,
              color: textColor ?? Colors.white,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  void _showClubDetails(BuildContext context) {
    // Navigation vers l'écran de détails du club
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ClubDetailScreen(club: club)),
    );
  }
}
