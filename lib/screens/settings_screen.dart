import 'dart:developer';

import 'package:espn_app/providers/provider_factory.dart';
import 'package:espn_app/providers/selected_league_notifier.dart';
import 'package:espn_app/providers/settings_provider.dart';
import 'package:espn_app/screens/color_picker_screen.dart';
import 'package:espn_app/widgets/widgets.dart';
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
    final selectedLeagueState = ref.watch(selectedLeagueProvider);
    final String leagueName = selectedLeagueState.$1;
    final assetService = ref.read(assetServiceProvider);

    // Observer les paramètres depuis le provider
    final settings = ref.watch(settingsProvider);

    // Obtenir le notifier pour mettre à jour les paramètres
    final settingsNotifier = ref.read(settingsProvider.notifier);

    final List<String> languages = [
      'English',
      'Français',
      'Español',
      'Deutsch',
    ];

    return Scaffold(
      body: Column(
        children: [
          // Custom AppBar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: CustomAppBar(
              url: assetService.getLeagueLogoUrl(leagueName),
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
              'SETTINGS',
              style: TextTheme.of(context).headlineMedium,
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
                      const SnackBar(
                        content: Text(
                          'Notifications are still under development',
                        ),
                      ),
                    );
                  },
                  child: _buildSettingSwitch(
                    'Notifications',
                    'Get the latest updates about matches',
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
                  'Dark Mode',
                  'Switch between light and dark theme',
                  Icons.brightness_6,
                  settings.darkModeEnabled,
                  (value) {
                    settingsNotifier.toggleDarkMode(value, context);
                  },
                ),

                const Divider(),

                // Language
                _buildSettingDropdown(
                  'Language',
                  'Select your preferred language',
                  Icons.language,
                  settings.language,
                  languages,
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
                  'Cache Data',
                  'Store data locally for faster loading',
                  Icons.storage,
                  settings.cacheEnabled,
                  (value) {
                    settingsNotifier.toggleCacheEnabled(value);
                  },
                ),

                const Divider(),

                // Clear Cache
                _buildSettingAction(
                  'Clear Cache',
                  'Delete all stored data',
                  Icons.cleaning_services,
                  () {
                    _showClearCacheDialog(context, settingsNotifier);
                  },
                ),

                const Divider(),

                // Color Picker
                _buildSettingAction(
                  'Color Picker',
                  'Select a color for the match widget',
                  Icons.color_lens,
                  () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ColorPickerScreen(),
                      ),
                    );
                  },
                ),

                const Divider(),

                // About
                _buildSettingAction(
                  'About',
                  'Learn more about the app',
                  Icons.info_outline,
                  () {
                    _showAboutDialog(context);
                  },
                ),

                const Divider(),

                // Visit ESPN
                _buildSettingAction(
                  'Visit ESPN',
                  'Go to the official ESPN website',
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
                        'Version $_version (Build $_buildNumber)',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Developed with Flutter',
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

  Widget _buildSettingSwitch(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    Function(bool) onChanged, {
    bool isDeactivated = false,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.black),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      subtitle: Text(subtitle),
      trailing: Switch(
        value: value,
        onChanged: isDeactivated ? null : onChanged,
        activeColor: isDeactivated ? Colors.grey : Colors.black,
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
    TextTheme textTheme,
    Function(String?) onChanged,
  ) {
    return ListTile(
      leading: Icon(icon, color: Colors.black),
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
                child: Text(option, style: textTheme.bodyMedium),
              );
            }).toList(),
        onChanged: onChanged,
        underline: Container(),
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
      leading: Icon(icon, color: Colors.black),
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
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Clear Cache'),
            content: const Text(
              'Are you sure you want to clear all cached data?',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('CANCEL'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  // Afficher un indicateur de chargement
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Clearing cache...'),
                      duration: Duration(seconds: 1),
                    ),
                  );

                  // Attendre que le cache soit effacé
                  await settingsNotifier.clearCache();

                  // Afficher un message de confirmation
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Cache cleared successfully'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
                child: const Text('CLEAR'),
              ),
            ],
          ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AboutDialog(
            applicationName: 'ESPN Soccer App',
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
              const Text(
                'A Flutter application for following soccer matches from around the world. '
                'Get live scores, match details, team statistics, and more.',
              ),
              const SizedBox(height: 20),
              const Text(
                '© 2025 Yann Bälli. All rights reserved.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    try {
      await launchUrl(uri);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not launch $url'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }
}
