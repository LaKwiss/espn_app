import 'package:espn_app/repositories/last_5_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Last5Notifier extends AsyncNotifier<List<int>> {
  late final Last5Repository _repository;

  /// Méthode qui appelle le repository pour récupérer la liste des 5 derniers résultats.
  Future<List<int>> get5last(String teamId) async {
    return _repository.getLast5(teamId);
  }

  @override
  Future<List<int>> build() async {
    _repository = Last5Repository();
    // Appel de la méthode interne get5last pour récupérer les données.
    return get5last('86');
  }
}

/// Provider family pour injecter le teamId lors de l'appel.
final last5Provider = AsyncNotifierProvider<Last5Notifier, List<int>>(
  () => Last5Notifier(),
);
