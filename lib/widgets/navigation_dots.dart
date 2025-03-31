// lib/widgets/navigation_dots.dart
import 'package:espn_app/providers/page_index_provider.dart';
import 'package:espn_app/widgets/widgets.dart'; // Assurez-vous que cela importe Material et GoogleFonts
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NavigationDots extends ConsumerWidget {
  const NavigationDots({super.key});

  // Valeurs de configuration intégrées
  static const double _baseDotSize = 7.0; // légèrement plus grand
  static const double _selectedDotSize = 10.0; // légèrement plus grand
  static const double _dotHorizontalMargin = 5.0; // un peu plus d'espace
  static const int _animationDurationMs = 250; // un peu plus rapide

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Obtenir l'index de page actuel et le thème
    final pageIndex = ref.watch(pageIndexProvider);
    final theme = Theme.of(context);
    // Utiliser la couleur primaire du thème pour les points
    final Color activeColor = theme.colorScheme.primary;
    final Color inactiveColor = theme.colorScheme.primary.withValues(
      alpha: 0.4,
    ); // Couleur inactive plus visible

    return SizedBox(
      // Augmenter un peu la largeur pour accommoder les points plus grands et plus espacés
      width: 160,
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center, // Centrer les points
          children: List.generate(3, (index) {
            // 3 points pour 3 écrans
            final bool isSelected = index == pageIndex;

            // Calculer la taille et la couleur du point en fonction de son état
            final double dotSize = isSelected ? _selectedDotSize : _baseDotSize;
            final Color dotColor = isSelected ? activeColor : inactiveColor;

            return GestureDetector(
              onTap: () {
                // Lire le PageController depuis le provider
                final pageController = ref.read(pageControllerProvider);
                if (pageController != null && pageController.hasClients) {
                  // Mettre à jour l'index via le provider D'ABORD
                  // ref.read(pageIndexProvider.notifier).state = index; // Redondant si on utilise animateToPage qui déclenche onPageChanged

                  // Animer le PageView vers la page sélectionnée
                  pageController.animateToPage(
                    index,
                    duration: const Duration(
                      milliseconds: _animationDurationMs,
                    ),
                    curve: Curves.easeInOut,
                  );
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: _animationDurationMs),
                margin: const EdgeInsets.symmetric(
                  horizontal: _dotHorizontalMargin,
                ),
                width: dotSize,
                height: dotSize,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                  // Optionnel: ajouter une petite ombre pour la profondeur
                  boxShadow:
                      isSelected
                          ? [
                            BoxShadow(
                              color: activeColor.withValues(alpha: 0.3),
                              blurRadius: 3,
                              spreadRadius: 1,
                            ),
                          ]
                          : [],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
