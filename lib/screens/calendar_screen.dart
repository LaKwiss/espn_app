import 'package:espn_app/class/event.dart';
import 'package:espn_app/providers/selected_league_notifier.dart';
import 'package:espn_app/repositories/event_repository.dart';
import 'package:espn_app/widgets/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
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
  bool _showUpcoming = true;
  bool _showCompleted = true;

  @override
  void initState() {
    super.initState();

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
      final events = await EventRepository.fetchEventsByDate(
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
    // Observer les changements dans la ligue sélectionnée
    final selectedLeagueState = ref.watch(selectedLeagueProvider);
    final String leagueName = selectedLeagueState.$1;
    final String leagueCode = selectedLeagueState.$2;

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
              url: _getLeagueLogoUrl(leagueName),
              backgroundColor: Colors.white,
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
                Text(
                  'CALENDAR',
                  style: GoogleFonts.blackOpsOne(
                    fontSize: 45,
                    color: Colors.black,
                    height: 1,
                  ),
                ),
                // Year Selector
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: DropdownButton<int>(
                    value: _selectedYear,
                    underline: Container(), // Supprimer la ligne par défaut
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
                                  style: GoogleFonts.roboto(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                  ),
                ),
              ],
            ),
          ),

          // Filter options
          _buildFilterOptions(),

          // Calendar widget
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: _buildCalendar(),
          ),

          // Date sélectionnée
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_today, color: Colors.black, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Date sélectionnée: ${DateFormat('d MMMM yyyy').format(_selectedDay)}',
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),

          // Selected day events
          Expanded(
            child:
                _isLoadingEvents
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage != null
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.red[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Erreur lors du chargement des matchs',
                            style: GoogleFonts.roboto(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.red[700],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.roboto(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _fetchEventsForSelectedDate,
                            child: const Text('Réessayer'),
                          ),
                        ],
                      ),
                    )
                    : _eventsForSelectedDate.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.sports_soccer_outlined,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Aucun match le ${DateFormat('d MMMM yyyy').format(_selectedDay)}',
                            style: GoogleFonts.roboto(
                              fontSize: 18,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Essayez de sélectionner une autre date ou ligue',
                            style: GoogleFonts.roboto(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                    : RefreshIndicator(
                      onRefresh: _fetchEventsForSelectedDate,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: _eventsForSelectedDate.length,
                        itemBuilder: (context, index) {
                          return MatchWidget(
                            event: _eventsForSelectedDate[index],
                          );
                        },
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterOptions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: FilterChip(
              label: const Text('À venir'),
              selected: _showUpcoming,
              onSelected: (selected) {
                setState(() {
                  _showUpcoming = selected;
                });
                _fetchEventsForSelectedDate();
              },
              checkmarkColor: Colors.black,
              selectedColor: Colors.grey[300],
              labelStyle: GoogleFonts.roboto(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: _showUpcoming ? Colors.black : Colors.grey,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: FilterChip(
              label: const Text('Terminés'),
              selected: _showCompleted,
              onSelected: (selected) {
                setState(() {
                  _showCompleted = selected;
                });
                _fetchEventsForSelectedDate();
              },
              checkmarkColor: Colors.black,
              selectedColor: Colors.grey[300],
              labelStyle: GoogleFonts.roboto(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: _showCompleted ? Colors.black : Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    return TableCalendar(
      firstDay: DateTime.utc(
        1970,
        1,
        1,
      ), // Très ancienne date pour permettre une grande navigation
      lastDay: DateTime.utc(2050, 12, 31), // Très future date
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
        selectedDecoration: BoxDecoration(
          color: Colors.black,
          shape: BoxShape.circle,
        ),
        todayDecoration: BoxDecoration(
          color: Colors.grey[400],
          shape: BoxShape.circle,
        ),
        markersMaxCount: 3,
        markerDecoration: const BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle,
        ),
      ),
      headerStyle: HeaderStyle(
        formatButtonVisible: true,
        titleCentered: true,
        formatButtonShowsNext: false,
        formatButtonDecoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        titleTextStyle: GoogleFonts.blackOpsOne(
          fontSize: 20,
          color: Colors.black,
        ),
      ),
    );
  }

  String _getLeagueLogoUrl(String leagueName) {
    switch (leagueName) {
      case 'Bundesliga':
        return 'https://a.espncdn.com/i/leaguelogos/soccer/500/10.png';
      case 'LALIGA':
        return 'https://a.espncdn.com/i/leaguelogos/soccer/500/15.png';
      case 'French Ligue 1':
        return 'https://a.espncdn.com/i/leaguelogos/soccer/500/9.png';
      case 'Premier League':
        return 'https://a.espncdn.com/i/leaguelogos/soccer/500/23.png';
      case 'Italian Serie A':
        return 'https://a.espncdn.com/i/leaguelogos/soccer/500/12.png';
      case 'UEFA Europa League':
        return 'https://a.espncdn.com/i/leaguelogos/soccer/500/2310.png';
      case 'Champions League':
        return 'https://a.espncdn.com/i/leaguelogos/soccer/500/2.png';
      default:
        return 'https://a.espncdn.com/i/leaguelogos/soccer/500/2.png';
    }
  }
}
