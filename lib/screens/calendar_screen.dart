import 'package:espn_app/class/event.dart';
import 'package:espn_app/providers/league_async_notifier.dart';
import 'package:espn_app/providers/selected_league_notifier.dart';
import 'package:espn_app/widgets/custom_app_bar.dart';
import 'package:espn_app/widgets/match_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
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

  // Filter options
  bool _showUpcoming = true;
  bool _showCompleted = true;

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(leagueAsyncProvider);
    final String leagueName = ref.watch(selectedLeagueProvider).$1;

    return Scaffold(
      body: Column(
        children: [
          // Custom AppBar
          CustomAppBar(
            url: _getLeagueLogoUrl(leagueName),
            backgroundColor: Colors.white,
          ),

          // Calendar Title
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Text(
              'CALENDAR',
              style: GoogleFonts.blackOpsOne(
                fontSize: 45,
                color: Colors.black,
                height: 1,
              ),
            ),
          ),

          // Filter options
          _buildFilterOptions(),

          // Calendar widget
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: _buildCalendar(),
          ),

          // Selected day events
          Expanded(
            child: eventsAsync.when(
              data: (allEvents) {
                // Filter events for the selected day
                final eventsForDay = _getEventsForDay(allEvents, _selectedDay);

                if (eventsForDay.isEmpty) {
                  return Center(
                    child: Text(
                      'No matches on this day',
                      style: GoogleFonts.roboto(
                        fontSize: 18,
                        color: Colors.grey,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: eventsForDay.length,
                  itemBuilder: (context, index) {
                    return MatchWidget(event: eventsForDay[index]);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error: $error')),
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
              label: const Text('Upcoming'),
              selected: _showUpcoming,
              onSelected: (selected) {
                setState(() {
                  _showUpcoming = selected;
                });
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
              label: const Text('Completed'),
              selected: _showCompleted,
              onSelected: (selected) {
                setState(() {
                  _showCompleted = selected;
                });
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
      firstDay: DateTime.utc(2024, 1, 1),
      lastDay: DateTime.utc(2025, 12, 31),
      focusedDay: _focusedDay,
      calendarFormat: _calendarFormat,
      selectedDayPredicate: (day) {
        return isSameDay(_selectedDay, day);
      },
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDay = selectedDay;
          _focusedDay = focusedDay;
        });
      },
      onFormatChanged: (format) {
        setState(() {
          _calendarFormat = format;
        });
      },
      onPageChanged: (focusedDay) {
        _focusedDay = focusedDay;
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

  List<Event> _getEventsForDay(List<Event> allEvents, DateTime day) {
    return allEvents.where((event) {
      final eventDate = DateTime.tryParse(event.date);
      if (eventDate == null) return false;

      final isSameDate =
          eventDate.year == day.year &&
          eventDate.month == day.month &&
          eventDate.day == day.day;

      // Apply filters
      if (!_showUpcoming && !event.isFinished) return false;
      if (!_showCompleted && event.isFinished) return false;

      return isSameDate;
    }).toList();
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
