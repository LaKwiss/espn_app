import 'package:espn_app/providers/page_index_provider.dart';
import 'package:espn_app/widgets/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NavigationDots extends ConsumerWidget {
  const NavigationDots({super.key});

  // Valeurs de configuration intégrées directement dans le widget
  static const double _baseDotSize = 6.0;
  static const double _selectedDotSize = 8.0;
  static const double _dotHorizontalMargin = 4.0;
  static const double _selectedOpacity = 1.0;
  static const double _unselectedOpacity = 0.5;
  static const int _animationDurationMs = 300;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Obtenir l'index de page actuel
    final pageIndex = ref.watch(pageIndexProvider);

    Color color = Theme.of(context).primaryColor;

    return SizedBox(
      width: 150,
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final bool isSelected = index == pageIndex;

            // Calculer la taille du point en fonction de son état
            final double dotSize = isSelected ? _selectedDotSize : _baseDotSize;

            return GestureDetector(
              onTap: () {
                // Mettre à jour l'index de la page et naviguer vers cette page
                ref.read(pageIndexProvider.notifier).state = index;

                // Navigation directe vers la page demandée
                ref.read(pageControllerProvider)?.jumpToPage(index);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: _animationDurationMs),
                margin: const EdgeInsets.symmetric(
                  horizontal: _dotHorizontalMargin,
                ),
                width: dotSize,
                height: dotSize,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            );
          }),
        ),
      ),
    );
  }
}
