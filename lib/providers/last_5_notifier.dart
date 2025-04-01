import 'package:espn_app/providers/provider_factory.dart';
import 'package:espn_app/repositories/last_5_repository/i_last_5_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Last5Notifier extends AsyncNotifier<List<int>> {
  late final ILast5Repository _repository;

  Future<List<int>> get5last(String teamId) async {
    try {
      return _repository.getLast5(teamId);
    } catch (e) {
      return List.filled(5, 0);
    }
  }

  @override
  Future<List<int>> build() async {
    _repository = ref.read(last5RepositoryProvider);
    return get5last('86');
  }
}

final last5Provider = AsyncNotifierProvider<Last5Notifier, List<int>>(
  () => Last5Notifier(),
);
