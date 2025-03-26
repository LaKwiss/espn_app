import 'package:espn_app/widgets/widgets.dart';
import 'package:flutter/material.dart';

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
    final theme = Theme.of(context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 7),
        Text(
          titleLine1.toUpperCase(),
          style: theme.textTheme.headlineLarge?.copyWith(height: 1),
        ),
        if (titleLine2 != null)
          Text(
            titleLine2!.toUpperCase(),
            style: theme.textTheme.headlineLarge?.copyWith(
              height: 1,
              color: theme.colorScheme.onBackground.withOpacity(0.5),
            ),
          ),
      ],
    );
  }
}
