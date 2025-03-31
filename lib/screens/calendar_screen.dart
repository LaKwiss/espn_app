// espn_app/lib/screens/calendar_screen.dart
import 'package:espn_app/models/event.dart';
import 'package:espn_app/providers/provider_factory.dart';
import 'package:espn_app/providers/selected_league_notifier.dart';
import 'package:espn_app/repositories/event_repository/i_event_repository.dart';
import 'package:espn_app/services/asset_service.dart';
import 'package:espn_app/services/date_formatter_service.dart';
import 'package:espn_app/widgets/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';

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

  List<int> _availableYears = [];

  List<Event> _eventsForSelectedDate = [];
  bool _isLoadingEvents = false;
  String? _errorMessage;

  final bool _showUpcoming = true;
  final bool _showCompleted = true;

  late final IEventRepository _eventRepository;
  late final AssetService _assetService;
  late final DateFormatterService _dateFormatter;

  @override
  void initState() {
    super.initState();

    _eventRepository = ref.read(eventRepositoryProvider);
    _assetService = ref.read(assetServiceProvider);
    _dateFormatter = ref.read(dateFormatterServiceProvider);

    _initAvailableYears();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final selectedState = ref.read(selectedLeagueProvider);
      final leagueCode = selectedState.$2.isEmpty ? 'ger.1' : selectedState.$2;

      if (selectedState.$2.isEmpty) {
        ref.read(selectedLeagueProvider.notifier).selectCode(leagueCode);
      }
      _fetchEventsForSelectedDate();
    });
  }

  void _initAvailableYears() {
    final currentYear = DateTime.now().year;
    _availableYears = List.generate(20, (index) => currentYear - 19 + index);
  }

  void _ensureYearIsAvailable() {
    if (!_availableYears.contains(_selectedYear)) {
      setState(() {
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
      final selectedState = ref.read(selectedLeagueProvider);
      final leagueCode = selectedState.$2.isEmpty ? 'ger.1' : selectedState.$2;
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
      //causing error
      setState(() {
        _errorMessage = AppLocalizations.of(context)!.errorLoadingMatches;
        _isLoadingEvents = false;
        _eventsForSelectedDate = [];
      });
    }
  }

  String _getLocalizedLeagueName(String leagueCode, AppLocalizations l10n) {
    switch (leagueCode) {
      case 'ger.1':
        return l10n.leagueBundesliga;
      case 'esp.1':
        return l10n.leagueLaLiga;
      case 'fra.1':
        return l10n.leagueLigue1;
      case 'eng.1':
        return l10n.leaguePremierLeague;
      case 'ita.1':
        return l10n.leagueSerieA;
      case 'uefa.europa':
        return l10n.leagueEuropaLeague;
      case 'uefa.champions':
        return l10n.leagueChampionsLeague;
      default:
        return l10n.leagueChampionsLeague; // Fallback
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentLocale = Localizations.localeOf(context).toString();

    final theme = Theme.of(context);
    final textTheme = ref.watch(themeProvider).textTheme;
    final colorScheme = theme.colorScheme;

    final selectedLeagueState = ref.watch(selectedLeagueProvider);
    final String leagueName = _getLocalizedLeagueName(
      selectedLeagueState.$2,
      l10n,
    );

    ref.listen<(String, String)>(selectedLeagueProvider, (previous, current) {
      if (previous?.$2 != current.$2) {
        _fetchEventsForSelectedDate();
      }
    });

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: CustomAppBar(
              url: _assetService.getLeagueLogoUrl(leagueName),
              backgroundColor: theme.scaffoldBackgroundColor,
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.calendarTitle, style: textTheme.headlineLarge),
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
                    underline: Container(),
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
                          _focusedDay = DateTime(
                            _selectedYear,
                            _focusedDay.month,
                            _focusedDay.day >
                                    DateTime(
                                      _selectedYear,
                                      _focusedDay.month + 1,
                                      0,
                                    ).day
                                ? DateTime(
                                  _selectedYear,
                                  _focusedDay.month + 1,
                                  0,
                                ).day
                                : _focusedDay.day,
                          );
                          _selectedDay = _focusedDay;
                        });

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

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: _buildCalendar(l10n),
          ),

          Expanded(
            child:
                _isLoadingEvents
                    ? Center(
                      child: CircularProgressIndicator(
                        color: colorScheme.primary,
                      ),
                    )
                    : _errorMessage != null
                    ? _buildErrorWidget(l10n)
                    : _eventsForSelectedDate.isEmpty
                    ? _buildEmptyEventsWidget(l10n, currentLocale)
                    : _buildEventsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(AppLocalizations l10n) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            l10n.errorLoadingMatches, // Utiliser la clé de localisation
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
            child: Text(l10n.tryAgain),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyEventsWidget(AppLocalizations l10n, String currentLocale) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final isDark = theme.brightness == Brightness.dark;
    final formattedDate = DateFormat.yMMMMd(currentLocale).format(_selectedDay);

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
            l10n.noMatchesOnDate(formattedDate),
            style: textTheme.bodyLarge?.copyWith(
              color: isDark ? Colors.grey[300] : Colors.grey[700],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.tryAnotherDateOrLeague,
            style: textTheme.bodyMedium,
            textAlign: TextAlign.center,
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

  Widget _buildCalendar(AppLocalizations l10n) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;
    final currentLocale = Localizations.localeOf(context).toString();

    return TableCalendar(
      locale: currentLocale,
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

          if (_selectedDay.year != _selectedYear) {
            _selectedYear = _selectedDay.year;
            _ensureYearIsAvailable();
          }
        });

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

          if (_focusedDay.year != _selectedYear) {
            _selectedYear = _focusedDay.year;
            _ensureYearIsAvailable();
          }
        });
      },
      calendarStyle: CalendarStyle(
        selectedDecoration: BoxDecoration(
          color: primaryColor,
          shape: BoxShape.circle,
        ),
        selectedTextStyle: TextStyle(
          color: isDark ? Colors.black : Colors.white,
          fontWeight: FontWeight.bold,
        ),

        todayDecoration: BoxDecoration(
          color: isDark ? Colors.grey[800] : Colors.grey[300],
          shape: BoxShape.circle,
        ),
        todayTextStyle: TextStyle(
          color: primaryColor,
          fontWeight: FontWeight.bold,
        ),

        defaultTextStyle: TextStyle(color: primaryColor),
        weekendTextStyle: TextStyle(
          color: isDark ? Colors.red[200] : Colors.red[700],
        ),
        outsideTextStyle: TextStyle(
          color: isDark ? Colors.grey[600] : Colors.grey[400],
        ),

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
        titleTextFormatter:
            (date, locale) => DateFormat.yMMMM(locale).format(date),
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
        dowTextFormatter:
            (date, locale) =>
                DateFormat.E(locale).format(date).substring(0, 1).toUpperCase(),
        weekdayStyle: TextStyle(
          color: primaryColor,
          fontWeight: FontWeight.bold,
        ),
        weekendStyle: TextStyle(
          color: isDark ? Colors.red[300] : Colors.red[700],
          fontWeight: FontWeight.bold,
        ),
      ),
      calendarBuilders: CalendarBuilders(
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
