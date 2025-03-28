import 'dart:developer';

import 'package:espn_app/providers/provider_factory.dart';
import 'package:espn_app/providers/selected_league_notifier.dart';
import 'package:espn_app/providers/settings_provider.dart';
import 'package:espn_app/screens/cache_analytics_screen.dart';
import 'package:espn_app/screens/color_picker_screen.dart';
import 'package:espn_app/widgets/widgets.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _version = "1.0.0";
  String _buildNumber = "1";

  @override
  void initState() {
    super.initState();
    _getPackageInfo();
  }

  Future<void> _getPackageInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _version = packageInfo.version;
        _buildNumber = packageInfo.buildNumber;
      });
    } catch (e) {
      log('Error getting package info: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Obtenir les traductions localisées
    final l10n = AppLocalizations.of(context)!;

    final selectedLeagueState = ref.watch(selectedLeagueProvider);

    final assetService = ref.read(assetServiceProvider);
    // Obtenir le nom anglais pour le service d'asset si nécessaire
    final String englishLeagueName = _getEnglishLeagueNameById(
      selectedLeagueState.$2,
    );

    // Observer les paramètres depuis le provider
    final settings = ref.watch(settingsProvider);

    // Obtenir le notifier pour mettre à jour les paramètres
    final settingsNotifier = ref.read(settingsProvider.notifier);

    final List<String> languageCodes =
        AppLocalizations.supportedLocales.map((l) => l.languageCode).toList();
    final Map<String, String> languageDisplayNames = {
      for (var locale in AppLocalizations.supportedLocales)
        locale.languageCode: l10n.languageName(locale.languageCode),
    };

    return Scaffold(
      body: Column(
        children: [
          // Custom AppBar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: CustomAppBar(
              url: assetService.getLeagueLogoUrl(
                englishLeagueName,
              ), // Use English name for URL if needed
              backgroundColor: AppBarTheme.of(context).backgroundColor,
            ),
          ),

          // Settings Title
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Text(
              l10n.settingsTitle,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),

          // Settings List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // Notifications
                GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          l10n.notificationsUnderDevelopment, // Utiliser la clé de localisation
                        ),
                      ),
                    );
                  },
                  child: _buildSettingSwitch(
                    l10n.notifications,
                    l10n.notificationsDescription,
                    Icons.notifications_none,
                    settings.notificationsEnabled,
                    (value) {
                      settingsNotifier.toggleNotifications(value);
                    },
                    isDeactivated: true,
                  ),
                ),

                const Divider(),

                // Dark Mode
                _buildSettingSwitch(
                  l10n.darkMode,
                  l10n.darkModeDescription,
                  Icons.brightness_6,
                  settings.darkModeEnabled,
                  (value) {
                    settingsNotifier.toggleDarkMode(value, context);
                  },
                ),

                const Divider(),

                // Language
                _buildSettingDropdown(
                  l10n.language,
                  l10n.languageDescription,
                  Icons.language,
                  settings.languageCode,
                  languageCodes,
                  languageDisplayNames,
                  Theme.of(context).textTheme,
                  (value) {
                    if (value != null) {
                      settingsNotifier.setLanguage(value);
                    }
                  },
                ),

                const Divider(),

                // Cache Data
                _buildSettingSwitch(
                  l10n.cacheData,
                  l10n.cacheDataDescription,
                  Icons.storage,
                  settings.cacheEnabled,
                  (value) {
                    settingsNotifier.toggleCacheEnabled(value);
                  },
                ),

                const Divider(),

                // Clear Cache
                _buildSettingAction(
                  l10n.clearCache,
                  l10n.clearCacheDescription,
                  Icons.cleaning_services,
                  () {
                    _showClearCacheDialog(context, settingsNotifier);
                  },
                ),

                const Divider(),

                // NEW: Cache Analytics
                _buildSettingAction(
                  'Cache Analytics',
                  'View detailed cache usage statistics and entries',
                  Icons.analytics_outlined,
                  () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const CacheAnalyticsScreen(),
                      ),
                    );
                  },
                ),

                const Divider(),

                // Color Picker
                _buildSettingAction(
                  l10n.colorPicker,
                  l10n.colorPickerDescription,
                  Icons.color_lens,
                  () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const ColorPickerScreen(),
                      ),
                    );
                  },
                ),

                const Divider(),

                // About
                _buildSettingAction(
                  l10n.about,
                  l10n.aboutDescription,
                  Icons.info_outline,
                  () {
                    _showAboutDialog(context);
                  },
                ),

                const Divider(),

                // Visit ESPN
                _buildSettingAction(
                  l10n.visitEspn,
                  l10n.visitEspnDescription,
                  Icons.sports_soccer,
                  () {
                    _launchUrl('https://www.espn.com/soccer/');
                  },
                ),

                const Divider(),

                const SizedBox(height: 40),

                // Version info
                Center(
                  child: Column(
                    children: [
                      Text(
                        l10n.versionInfo(
                          _version,
                          _buildNumber,
                        ), // Clé avec paramètres
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.developedWith,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Retourne le nom ANGLAIS basé sur l'ID pour la correspondance de logo
  String _getEnglishLeagueNameById(String leagueId) {
    switch (leagueId) {
      case 'ger.1':
        return 'Bundesliga';
      case 'esp.1':
        return 'LALIGA';
      case 'fra.1':
        return 'French Ligue 1';
      case 'eng.1':
        return 'Premier League';
      case 'ita.1':
        return 'Italian Serie A';
      case 'uefa.europa':
        return 'UEFA Europa League';
      case 'uefa.champions':
        return 'Champions League';
      default:
        return 'Champions League';
    }
  }

  Widget _buildSettingSwitch(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    Function(bool) onChanged, {
    bool isDeactivated = false,
  }) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.onBackground),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      subtitle: Text(subtitle),
      trailing: Switch(
        value: value,
        onChanged: isDeactivated ? null : onChanged,
        activeColor:
            isDeactivated ? Colors.grey : Theme.of(context).colorScheme.primary,
        inactiveThumbColor: isDeactivated ? Colors.white : null,
        trackColor:
            isDeactivated ? MaterialStateProperty.all(Colors.grey[300]) : null,
      ),
    );
  }

  Widget _buildSettingDropdown(
    String title,
    String subtitle,
    IconData icon,
    String value,
    List<String> options,
    Map<String, String> displayNames,
    TextTheme textTheme,
    Function(String?) onChanged,
  ) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.onBackground),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      subtitle: Text(subtitle),
      trailing: DropdownButton<String>(
        value: value,
        items:
            options.map((String option) {
              return DropdownMenuItem<String>(
                value: option,
                child: Text(
                  displayNames[option] ?? option,
                  style: textTheme.bodyMedium,
                ),
              );
            }).toList(),
        onChanged: onChanged,
        underline: Container(), // Remove the default underline
        dropdownColor: Theme.of(context).cardColor, // Match theme
      ),
    );
  }

  Widget _buildSettingAction(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.onBackground),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  void _showClearCacheDialog(
    BuildContext context,
    SettingsNotifier settingsNotifier,
  ) {
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(l10n.clearCache),
            content: Text(l10n.clearCacheConfirmation), // Clé de localisation
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(l10n.cancel), // Clé de localisation
              ),
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  // Afficher un indicateur de chargement
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.clearingCache), // Clé de localisation
                      duration: const Duration(seconds: 1),
                    ),
                  );

                  // Attendre que le cache soit effacé
                  await settingsNotifier.clearCache();

                  // Afficher un message de confirmation
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.cacheCleared), // Clé de localisation
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
                child: Text(l10n.clear), // Clé de localisation
              ),
            ],
          ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder:
          (context) => AboutDialog(
            applicationName: l10n.appTitle,
            applicationVersion: '$_version',
            applicationIcon: Image.network(
              'https://a.espncdn.com/i/espn/misc_logos/500/espn_red.png',
              width: 50,
              height: 50,
              errorBuilder:
                  (context, error, stackTrace) =>
                      const Icon(Icons.sports_soccer, size: 50),
            ),
            children: [
              Text(l10n.aboutAppDescription), // Clé de localisation
              const SizedBox(height: 20),
              Text(
                l10n.copyright, // Clé de localisation
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final l10n = AppLocalizations.of(context)!; // Get localizations
    final Uri uri = Uri.parse(url);
    try {
      if (!await launchUrl(uri)) {
        throw Exception('Could not launch $url'); // Throw specific error
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.couldNotLaunchUrl(url)), // Use localized message
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }
}
