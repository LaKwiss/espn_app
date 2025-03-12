import 'package:espn_app/widgets/widgets.dart';

class HomeScreenTitle extends StatelessWidget {
  const HomeScreenTitle({
    required this.titleLine1,
    this.titleLine2 = '',
    super.key,
  });

  final String titleLine1;
  final String? titleLine2;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 7),
        Text(
          titleLine1.toUpperCase(),
          style: GoogleFonts.blackOpsOne(
            fontSize: 45,
            color: Colors.black,
            height: 1,
          ),
        ),
        if (titleLine2 != null)
          Text(
            titleLine2!.toUpperCase(),
            style: GoogleFonts.blackOpsOne(
              fontSize: 45,
              color: Colors.black.withValues(alpha: 0.5),
              height: 1,
            ),
          ),
      ],
    );
  }
}
