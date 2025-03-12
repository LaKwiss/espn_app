import 'package:espn_app/widgets/widgets.dart';

class CallToActionWidget extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  final Color backgroundColor;
  final Color textColor;
  final double fontSize;

  const CallToActionWidget({
    super.key,
    required this.text,
    this.onTap,
    this.backgroundColor = const Color(0xFFF55E42),
    this.textColor = Colors.black,
    this.fontSize = 32,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24),
        color: backgroundColor,
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: GoogleFonts.blackOpsOne(fontSize: fontSize, color: textColor),
        ),
      ),
    );
  }
}
