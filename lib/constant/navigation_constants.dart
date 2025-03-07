/// Constantes pour les dimensions des indicateurs de navigation
class NavigationConstants {
  // Tailles des points de navigation
  static const double baseDotSize =
      6.0; // Taille de base d'un point non sélectionné
  static const double selectedDotSize = 8.0; // Taille d'un point sélectionné
  static const double middleDotExtraSize =
      4.0; // Bonus supplémentaire pour le point du milieu quand sélectionné

  // Marges et espacements
  static const double dotHorizontalMargin =
      4.0; // Marge horizontale entre les points

  // Opacités
  static const double selectedOpacity = 1.0; // Opacité d'un point sélectionné
  static const double unselectedOpacity =
      0.5; // Opacité d'un point non sélectionné

  // Animation
  static const int animationDurationMs =
      300; // Durée de l'animation en millisecondes
}
