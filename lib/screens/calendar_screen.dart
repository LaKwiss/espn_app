import 'package:espn_app/models/event.dart';
import 'package:espn_app/providers/provider_factory.dart';
import 'package:espn_app/providers/selected_league_notifier.dart';
import 'package:espn_app/providers/theme_provider.dart';
import 'package:espn_app/repositories/event_repository/i_event_repository.dart';
import 'package:espn_app/services/asset_service.dart';
import 'package:espn_app/services/date_formatter_service.dart';
import 'package:espn_app/widgets/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  int _selectedYear = DateTime.now().year;

  // Liste des 20 dernières années
  List<int> _availableYears = [];

  // Événements pour la date sélectionnée
  List<Event> _eventsForSelectedDate = [];
  bool _isLoadingEvents = false;
  String? _errorMessage;

  // Options de filtre
  final bool _showUpcoming = true;
  final bool _showCompleted = true;

  // Services
  late final IEventRepository _eventRepository;
  late final AssetService _assetService;
  late final DateFormatterService _dateFormatter;

  @override
  void initState() {
    super.initState();

    // Initialiser les services immédiatement
    _eventRepository = ref.read(eventRepositoryProvider);
    _assetService = ref.read(assetServiceProvider);
    _dateFormatter = ref.read(dateFormatterServiceProvider);

    // Initialiser la liste des années disponibles
    _initAvailableYears();

    // Initialiser la ligue et récupérer les événements initiaux
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final selectedState = ref.read(selectedLeagueProvider);
      final leagueCode = selectedState.$2.isEmpty ? 'ger.1' : selectedState.$2;

      // Si aucune ligue n'est sélectionnée, utiliser 'ger.1' par défaut
      if (selectedState.$2.isEmpty) {
        ref.read(selectedLeagueProvider.notifier).selectCode(leagueCode);
        ref.read(selectedLeagueProvider.notifier).selectLeague('Bundesliga');
      }

      // Récupérer les événements initiaux pour aujourd'hui
      _fetchEventsForSelectedDate();
    });
  }

  // Initialise la liste des 20 dernières années
  void _initAvailableYears() {
    final currentYear = DateTime.now().year;
    _availableYears = List.generate(20, (index) => currentYear - 19 + index);
  }

  // S'assure que l'année sélectionnée est dans la liste des années disponibles
  void _ensureYearIsAvailable() {
    if (!_availableYears.contains(_selectedYear)) {
      setState(() {
        // Régénérer la liste centrée autour de l'année sélectionnée
        _availableYears = List.generate(
          20,
          (index) => _selectedYear - 10 + index,
        );
      });
    }
  }

  Future<void> _fetchEventsForSelectedDate() async {
    if (_isLoadingEvents) return;

    setState(() {
      _isLoadingEvents = true;
      _errorMessage = null;
    });

    try {
      // Obtenir le code de la ligue sélectionnée ou utiliser 'ger.1' par défaut
      final selectedState = ref.read(selectedLeagueProvider);
      final leagueCode = selectedState.$2.isEmpty ? 'ger.1' : selectedState.$2;

      // Récupérer les événements pour la date et la ligue sélectionnées
      final events = await _eventRepository.fetchEventsByDate(
        leagueCode,
        _selectedDay,
      );

      // Appliquer les filtres
      final filteredEvents =
          events.where((event) {
            if (!_showUpcoming && !event.isFinished) return false;
            if (!_showCompleted && event.isFinished) return false;
            return true;
          }).toList();

      setState(() {
        _eventsForSelectedDate = filteredEvents;
        _isLoadingEvents = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Échec du chargement des événements: $e';
        _isLoadingEvents = false;
        _eventsForSelectedDate = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Obtenir le thème courant
    final theme = Theme.of(context);
    final textTheme = ref.watch(themeProvider).textTheme;
    final colorScheme = theme.colorScheme;

    // Observer les changements dans la ligue sélectionnée
    final selectedLeagueState = ref.watch(selectedLeagueProvider);
    final String leagueName = selectedLeagueState.$1;

    // Si la ligue a changé, recharger les événements
    ref.listen<(String, String)>(selectedLeagueProvider, (previous, current) {
      if (previous?.$2 != current.$2) {
        _fetchEventsForSelectedDate();
      }
    });

    return Scaffold(
      body: Column(
        children: [
          // Custom AppBar - Utilise le comportement par défaut pour le LeagueSelector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: CustomAppBar(
              url: _assetService.getLeagueLogoUrl(leagueName),
              backgroundColor: theme.scaffoldBackgroundColor,
            ),
          ),

          // Calendar Title avec sélecteur d'année
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('CALENDAR', style: textTheme.headlineLarge),
                // Year Selector
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  decoration: BoxDecoration(
                    color:
                        theme.brightness == Brightness.light
                            ? Colors.grey[200]
                            : Colors.grey[800],
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: DropdownButton<int>(
                    value: _selectedYear,
                    underline: Container(), // Supprimer la ligne par défaut
                    dropdownColor:
                        theme.brightness == Brightness.light
                            ? Colors.grey[200]
                            : Colors.grey[800],
                    icon: Icon(
                      Icons.arrow_drop_down,
                      color: colorScheme.primary,
                    ),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedYear = value;
                          // Mettre à jour le jour focalisé avec l'année sélectionnée
                          _focusedDay = DateTime(
                            _selectedYear,
                            _focusedDay.month,
                            // S'assurer que le jour est valide dans le nouveau mois/année
                            _focusedDay.day >
                                    DateTime(
                                      _selectedYear,
                                      _focusedDay.month,
                                      0,
                                    ).day
                                ? DateTime(
                                  _selectedYear,
                                  _focusedDay.month,
                                  0,
                                ).day
                                : _focusedDay.day,
                          );
                          _selectedDay = _focusedDay;
                        });

                        // Récupérer les événements pour la nouvelle date
                        _fetchEventsForSelectedDate();
                      }
                    },
                    items:
                        _availableYears
                            .map(
                              (year) => DropdownMenuItem<int>(
                                value: year,
                                child: Text(
                                  year.toString(),
                                  style: textTheme.labelLarge,
                                ),
                              ),
                            )
                            .toList(),
                  ),
                ),
              ],
            ),
          ),

          // Calendar widget
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: _buildCalendar(),
          ),

          // Selected day events
          Expanded(
            child:
                _isLoadingEvents
                    ? Center(
                      child: CircularProgressIndicator(
                        color: colorScheme.primary,
                      ),
                    )
                    : _errorMessage != null
                    ? _buildErrorWidget()
                    : _eventsForSelectedDate.isEmpty
                    ? _buildEmptyEventsWidget()
                    : _buildEventsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            'Erreur lors du chargement des matchs',
            style: textTheme.titleMedium?.copyWith(color: Colors.red[700]),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _fetchEventsForSelectedDate,
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyEventsWidget() {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.sports_soccer_outlined,
            size: 48,
            color: isDark ? Colors.grey[400] : Colors.grey[500],
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun match le ${_dateFormatter.formatDate(_selectedDay)}',
            style: textTheme.bodyLarge?.copyWith(
              color: isDark ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Essayez de sélectionner une autre date ou ligue',
            style: textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildEventsList() {
    return RefreshIndicator(
      onRefresh: _fetchEventsForSelectedDate,
      color: Theme.of(context).colorScheme.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _eventsForSelectedDate.length,
        itemBuilder: (context, index) {
          return MatchWidget(event: _eventsForSelectedDate[index]);
        },
      ),
    );
  }

  Widget _buildCalendar() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;

    return TableCalendar(
      firstDay: DateTime.utc(1970, 1, 1),
      lastDay: DateTime.utc(2050, 12, 31),
      focusedDay: _focusedDay,
      calendarFormat: _calendarFormat,
      selectedDayPredicate: (day) {
        return isSameDay(_selectedDay, day);
      },
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDay = selectedDay;
          _focusedDay = focusedDay;

          // Mettre à jour l'année sélectionnée si nécessaire
          if (_selectedDay.year != _selectedYear) {
            _selectedYear = _selectedDay.year;
            _ensureYearIsAvailable();
          }
        });

        // Récupérer les événements pour la date sélectionnée
        _fetchEventsForSelectedDate();
      },
      onFormatChanged: (format) {
        setState(() {
          _calendarFormat = format;
        });
      },
      onPageChanged: (focusedDay) {
        setState(() {
          _focusedDay = focusedDay;

          // Mettre à jour l'année si elle a changé
          if (_focusedDay.year != _selectedYear) {
            _selectedYear = _focusedDay.year;
            _ensureYearIsAvailable();
          }
        });
      },
      calendarStyle: CalendarStyle(
        // Jour sélectionné
        selectedDecoration: BoxDecoration(
          color: primaryColor,
          shape: BoxShape.circle,
        ),
        selectedTextStyle: TextStyle(
          color: isDark ? Colors.black : Colors.white,
          fontWeight: FontWeight.bold,
        ),

        // Aujourd'hui
        todayDecoration: BoxDecoration(
          color: isDark ? Colors.grey[800] : Colors.grey[300],
          shape: BoxShape.circle,
        ),
        todayTextStyle: TextStyle(
          color: primaryColor,
          fontWeight: FontWeight.bold,
        ),

        // Jours normaux
        defaultTextStyle: TextStyle(color: primaryColor),
        weekendTextStyle: TextStyle(
          color: isDark ? Colors.red[200] : Colors.red[700],
        ),
        outsideTextStyle: TextStyle(
          color: isDark ? Colors.grey[600] : Colors.grey[400],
        ),

        // Marqueurs
        markersMaxCount: 3,
        markerDecoration: BoxDecoration(
          color: isDark ? Colors.red[700] : Colors.red,
          shape: BoxShape.circle,
        ),
        markerSize: 7.0,
      ),
      headerStyle: HeaderStyle(
        formatButtonVisible: true,
        titleCentered: true,
        formatButtonShowsNext: false,
        formatButtonDecoration: BoxDecoration(
          color: isDark ? Colors.grey[800] : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        formatButtonTextStyle: theme.textTheme.labelLarge!,
        titleTextStyle: theme.textTheme.titleMedium!,
        leftChevronIcon: Icon(Icons.chevron_left, color: primaryColor),
        rightChevronIcon: Icon(Icons.chevron_right, color: primaryColor),
        headerMargin: const EdgeInsets.symmetric(vertical: 8.0),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      daysOfWeekStyle: DaysOfWeekStyle(
        weekdayStyle: TextStyle(
          color: primaryColor,
          fontWeight: FontWeight.bold,
        ),
        weekendStyle: TextStyle(
          color: isDark ? Colors.red[300] : Colors.red[700],
          fontWeight: FontWeight.bold,
        ),
      ),
      // Style global
      calendarBuilders: CalendarBuilders(
        // Personnalisation du marqueur d'événements
        markerBuilder: (context, date, events) {
          if (events.isNotEmpty) {
            return Positioned(
              bottom: 1,
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? Colors.red[700] : Colors.red,
                ),
              ),
            );
          }
          return null;
        },
      ),
    );
  }
}
