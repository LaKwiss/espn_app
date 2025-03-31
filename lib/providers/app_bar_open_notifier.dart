import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppBarOpenNotifier extends AsyncNotifier<bool> {
  @override
  FutureOr<bool> build() => false;

  Future<void> openNavBar() async {
    state = AsyncValue.loading();
    state = AsyncData(true);
  }

  Future<void> closeNavBar() async {
    state = AsyncValue.loading();
    await Future.delayed(const Duration(milliseconds: 350));
    state = AsyncData(false);
  }
}
