import 'package:espn_app/providers/app_bar_open_notifier.dart';
import 'package:espn_app/providers/cache_stats_tracker.dart';
import 'package:espn_app/providers/colors_provider.dart';
import 'package:espn_app/providers/theme_provider.dart';
import 'package:espn_app/repositories/athlete_repository/athlete_repository.dart';
import 'package:espn_app/repositories/athlete_repository/i_athlete_repository.dart';
import 'package:espn_app/repositories/formation_repository/formation_repository.dart';
import 'package:espn_app/repositories/formation_repository/i_formation_repository.dart';
import 'package:espn_app/repositories/last_5_repository/i_last_5_repository.dart';
import 'package:espn_app/repositories/league_picture_repository/i_league_repository.dart';
import 'package:espn_app/providers/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:espn_app/services/api_service.dart';
import 'package:espn_app/services/error_handler_service.dart';
import 'package:espn_app/services/date_formatter_service.dart';
import 'package:espn_app/services/asset_service.dart';
import 'package:espn_app/services/hive_cache_service.dart';
import 'package:espn_app/repositories/event_repository/event_repository.dart';
import 'package:espn_app/repositories/event_repository/i_event_repository.dart';
import 'package:espn_app/repositories/match_event_repository/match_event_repository.dart';
import 'package:espn_app/repositories/match_event_repository/i_match_event_repository.dart';
import 'package:espn_app/repositories/last_5_repository/last_5_repository.dart';
import 'package:espn_app/repositories/league_picture_repository/league_picture_repository.dart';

final hiveCacheServiceProvider = Provider<HiveCacheService>((ref) {
  return HiveCacheService();
});

final cacheStatsProvider = Provider<CacheStatsTracker>((ref) {
  return CacheStatsTracker();
});

final apiServiceProvider = Provider<ApiService>((ref) {
  final settings = ref.watch(settingsProvider);
  final cacheService = ref.watch(hiveCacheServiceProvider);

  return ApiService(
    cacheService: cacheService,
    cacheEnabled: settings.cacheEnabled,
    defaultCacheDuration: const Duration(hours: 4),
    logCacheHits: true,
    providerRef: ref,
  );
});

final errorHandlerServiceProvider = Provider<ErrorHandlerService>(
  (ref) => ErrorHandlerService(),
);

final dateFormatterServiceProvider = Provider<DateFormatterService>(
  (ref) => DateFormatterService(),
);

final assetServiceProvider = Provider<AssetService>((ref) => AssetService());

final eventRepositoryProvider = Provider<IEventRepository>((ref) {
  return EventRepository(
    apiService: ref.watch(apiServiceProvider),
    errorHandler: ref.watch(errorHandlerServiceProvider),
  );
});

final matchEventRepositoryProvider = Provider<IMatchEventRepository>((ref) {
  return MatchEventRepository(
    apiService: ref.watch(apiServiceProvider),
    errorHandler: ref.watch(errorHandlerServiceProvider),
  );
});

final last5RepositoryProvider = Provider<ILast5Repository>((ref) {
  return Last5Repository(
    apiService: ref.watch(apiServiceProvider),
    errorHandler: ref.watch(errorHandlerServiceProvider),
  );
});

final leaguePictureRepositoryProvider = Provider<ILeaguePictureRepository>((
  ref,
) {
  return LeaguePictureRepository(
    apiService: ref.watch(apiServiceProvider),
    errorHandler: ref.watch(errorHandlerServiceProvider),
  );
});

final athletesRepositoryProvider = Provider<IAthletesRepository>((ref) {
  return AthletesRepository(
    apiService: ref.watch(apiServiceProvider),
    errorHandler: ref.watch(errorHandlerServiceProvider),
  );
});

final formationRepositoryProvider = Provider<IFormationRepository>((ref) {
  return FormationRepository(
    apiService: ref.watch(apiServiceProvider),
    errorHandler: ref.watch(errorHandlerServiceProvider),
  );
});

final colorsProvider = StateNotifierProvider<ColorsNotifier, List<Color>>(
  (ref) => ColorsNotifier(),
);

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((
  ref,
) {
  return SettingsNotifier();
});

final themeProvider = Provider<ThemeData>((ref) {
  final settings = ref.watch(settingsProvider);

  return settings.darkModeEnabled ? darkTheme : lightTheme;
});

final leagueSelectorVisibilityProvider =
    AsyncNotifierProvider<AppBarOpenNotifier, bool>(() => AppBarOpenNotifier());
