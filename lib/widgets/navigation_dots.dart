import 'package:espn_app/constant/navigation_constants.dart';
import 'package:espn_app/providers/page_index_provider.dart';
import 'package:espn_app/widgets/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NavigationDots extends ConsumerWidget {
  const NavigationDots({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Obtenir l'index de page actuel
    final pageIndex = ref.watch(pageIndexProvider);

    return SizedBox(
      width: 150,
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            bool isSelected = index == pageIndex;

            // Calculer la taille du point en fonction de son état et de sa position
            double dotSize = NavigationConstants.baseDotSize;
            if (isSelected) {
              dotSize = NavigationConstants.selectedDotSize;
              // Si le point du milieu est sélectionné, il est encore plus grand
            }

            return GestureDetector(
              onTap: () {
                // Mettre à jour l'index de la page et naviguer vers cette page
                ref.read(pageIndexProvider.notifier).state = index;

                // Navigation directe vers la page demandée
                ref.read(pageControllerProvider)?.jumpToPage(index);
              },
              child: Container(
                margin: EdgeInsets.symmetric(
                  horizontal: NavigationConstants.dotHorizontalMargin,
                ),
                width: dotSize,
                height: dotSize,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(
                    alpha:
                        isSelected
                            ? NavigationConstants.selectedOpacity
                            : NavigationConstants.unselectedOpacity,
                  ),
                  shape: BoxShape.circle,
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
