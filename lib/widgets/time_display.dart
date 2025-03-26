import 'package:espn_app/widgets/widgets.dart';

class TimeDisplay extends StatelessWidget {
  const TimeDisplay({super.key, required this.time, required this.randomColor});

  final String time;
  final Color randomColor;

  @override
  Widget build(BuildContext context) {
    final timeParts = time.split(':');
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '${timeParts[0]}:',
          style: GoogleFonts.blackOpsOne(
            fontSize: 60,
            color:
                Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
          ),
        ),
        Text(
          timeParts[1],
          style: GoogleFonts.blackOpsOne(fontSize: 60, color: randomColor),
        ),
      ],
    );
  }
}
