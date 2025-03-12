import 'package:espn_app/providers/provider_factory.dart';
import 'package:espn_app/repositories/last_5_repository/i_last_5_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Last5Notifier extends AsyncNotifier<List<int>> {
  late final ILast5Repository _repository;

  /// Méthode qui appelle le repository pour récupérer la liste des 5 derniers résultats.
  Future<List<int>> get5last(String teamId) async {
    try {
      return _repository.getLast5(teamId);
    } catch (e) {
      // Retourner une liste de valeurs par défaut en cas d'erreur
      return List.filled(5, 0);
    }
  }

  @override
  Future<List<int>> build() async {
    _repository = ref.read(last5RepositoryProvider);
    // Appel de la méthode interne get5last pour récupérer les données.
    return get5last('86');
  }
}

/// Provider family pour injecter le teamId lors de l'appel.
final last5Provider = AsyncNotifierProvider<Last5Notifier, List<int>>(
  () => Last5Notifier(),
);
