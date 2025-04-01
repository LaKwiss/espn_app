class Probability {
  final double value;

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

  static Probability empty() {
    return Probability(value: 0);
  }
}
