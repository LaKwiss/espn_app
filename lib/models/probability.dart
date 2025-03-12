// Classe qui représente une probabilité implicite calculée à partir d'une cote décimale.
class Probability {
  final double value; // valeur comprise entre 0 et 1 (ex. 0.488 = 48.8%)

  Probability({required this.value});

  /// Calcule la probabilité implicite à partir d'une cote décimale.
  factory Probability.fromDecimalOdds(double odds) {
    if (odds <= 0) {
      throw Exception("La cote doit être supérieure à 0");
    }
    return Probability(value: 1 / odds);
  }

  @override
  String toString() => "${(value * 100).toStringAsFixed(1)}%";
}
