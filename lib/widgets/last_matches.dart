import 'package:espn_app/widgets/widgets.dart';

class LastMatches extends StatelessWidget {
  const LastMatches({super.key, required this.results});

  final List<String> results;

  @override
  Widget build(BuildContext context) {
    // Use actual form results or a default list
    final formResults =
        results.isNotEmpty ? results : ['W', 'D', 'L', 'W', 'W'];

    // Map result codes to colors
    final colors = {'W': Colors.green, 'D': Colors.orange, 'L': Colors.red};

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children:
          formResults.take(5).map((result) {
            return Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors[result] ?? Colors.grey,
              ),
              child: Center(
                child: Text(
                  result,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            );
          }).toList(),
    );
  }
}
