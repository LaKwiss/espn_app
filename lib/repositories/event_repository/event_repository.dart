import 'dart:convert';
import 'dart:developer' as dev;
import 'package:espn_app/repositories/event_repository/i_event_repository.dart';
import 'package:espn_app/services/api_service.dart';
import 'package:espn_app/services/error_handler_service.dart';
import 'package:espn_app/models/event.dart';

class EventRepository implements IEventRepository {
  final ApiService _apiService;
  final ErrorHandlerService _errorHandler;

  // Cache durations based on data staleness
  static const Duration _leagueCacheDuration = Duration(
    days: 3,
  ); // League info rarely changes
  static const Duration _eventsCacheDuration = Duration(
    hours: 1,
  ); // Schedule may update
  static const Duration _finishedEventCacheDuration = Duration(
    days: 7,
  ); // Completed events won't change
  static const Duration _upcomingEventCacheDuration = Duration(
    hours: 2,
  ); // Upcoming events might have minor changes

  EventRepository({
    required ApiService apiService,
    required ErrorHandlerService errorHandler,
  }) : _apiService = apiService,
       _errorHandler = errorHandler;

  @override
  Future<List<Event>> fetchEventsFromLeague(String league) async {
    dev.log('Starting fetchEventsFromLeague for: $league');

    final url =
        'http://sports.core.api.espn.com/v2/sports/soccer/leagues/$league/events';
    dev.log('Fetching from URL: $url');

    try {
      // Use cache for league events
      final response = await _apiService.get(
        url,
        cacheDuration: _eventsCacheDuration,
      );

      dev.log('Response status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        // Log response body length for debugging
        dev.log('Response body length: ${response.body.length} characters');

        // Decode response body
        final Map<String, dynamic> data = jsonDecode(response.body);

        // Extract event URLs
        final List<dynamic> items = data['items'];
        dev.log('Found ${items.length} event items in response');

        if (items.isEmpty) {
          dev.log('WARNING: No events found for league: $league');
          return [];
        }

        final List<String> eventUrls =
            items.map<String>((item) => item['\$ref'] as String).toList();

        // Fetch details for each event
        final futures =
            eventUrls.map<Future<Event>>((url) async {
              dev.log('Fetching event details from: $url');

              try {
                // Fetch event data with appropriate cache duration
                final eventResponse = await _apiService.get(url);
                if (eventResponse.statusCode != 200) {
                  throw Exception(
                    'Failed to load event from $url, status: ${eventResponse.statusCode}',
                  );
                }

                final Map<String, dynamic> eventJson = jsonDecode(
                  eventResponse.body,
                );

                // Determine if event is finished to use appropriate cache duration
                bool isFinished = _isEventFinished(eventJson);

                // Get competition data
                if (!eventJson.containsKey('competitions') ||
                    eventJson['competitions'].isEmpty) {
                  throw Exception(
                    'No competition data found for event at $url',
                  );
                }

                final competition = eventJson['competitions'][0];

                // Get odds URL
                if (!competition.containsKey('odds') ||
                    competition['odds'] == null ||
                    !competition['odds'].containsKey('\$ref')) {
                  dev.log('No odds data found for event, using default values');
                  // Create mock odds data with default probabilities
                  final mockOddsJson = {
                    'items': [
                      {
                        'provider': {'id': '2000'},
                        'awayTeamOdds': {
                          'odds': {'value': 3.0},
                        },
                        'homeTeamOdds': {
                          'odds': {'value': 2.1},
                        },
                        'drawOdds': {'value': 3.4},
                      },
                    ],
                  };
                  return Event.fromJson(eventJson, mockOddsJson);
                }

                final String oddsUrl = competition['odds']['\$ref'] as String;
                dev.log('Fetching odds from: $oddsUrl');

                // Fetch odds data - cache duration depends on event status
                final Duration oddsCacheDuration =
                    isFinished
                        ? _finishedEventCacheDuration
                        : _upcomingEventCacheDuration;

                final oddsResponse = await _apiService.get(
                  oddsUrl,
                  cacheDuration: oddsCacheDuration,
                );

                if (oddsResponse.statusCode != 200) {
                  throw Exception(
                    'Failed to load odds from $oddsUrl, status: ${oddsResponse.statusCode}',
                  );
                }

                final Map<String, dynamic> oddsJson = jsonDecode(
                  oddsResponse.body,
                );

                // Create Event object
                return Event.fromJson(eventJson, oddsJson);
              } catch (e, stack) {
                return _errorHandler.handleError<Event>(
                  e,
                  stack,
                  'processing event $url',
                );
              }
            }).toList();

        try {
          final result = await Future.wait(futures);
          dev.log(
            'Successfully fetched ${result.length} events for league: $league',
          );
          return result;
        } catch (e) {
          dev.log('Error during Future.wait: $e');
          rethrow;
        }
      } else {
        throw Exception(
          'Failed to load events for league: $league, status: ${response.statusCode}',
        );
      }
    } catch (e, stack) {
      return _errorHandler.handleError<List<Event>>(
        e,
        stack,
        'fetchEventsFromLeague',
        defaultValue: [],
      );
    }
  }

  @override
  Future<String> fetchLeagueName(String leagueName) async {
    dev.log('Fetching league name for: $leagueName');

    try {
      // League names rarely change, so we can cache them for longer
      final response = await _apiService.get(
        'http://sports.core.api.espn.com/v2/sports/soccer/leagues/$leagueName',
        cacheDuration: _leagueCacheDuration,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final String name = data['displayName'] as String;
        dev.log('League name fetched: $name');
        return name;
      } else {
        dev.log('Error fetching league name: ${response.statusCode}');
        throw Exception(
          'Failed to load league: $leagueName, status: ${response.statusCode}',
        );
      }
    } catch (e, stack) {
      return _errorHandler.handleError<String>(
        e,
        stack,
        'fetchLeagueName',
        defaultValue: leagueName,
      );
    }
  }

  @override
  Future<List<Event>> fetchEventsByDate(String league, DateTime date) async {
    final formattedDate =
        '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
    dev.log('Fetching events for league: $league on date: $formattedDate');

    final url =
        'http://sports.core.api.espn.com/v2/sports/soccer/leagues/$league/events?dates=$formattedDate';
    dev.log('Fetching from URL: $url');

    try {
      // Use cache with appropriate duration based on date
      final bool isDateInPast = date.isBefore(
        DateTime.now().subtract(const Duration(days: 1)),
      );
      final cacheDuration =
          isDateInPast ? _finishedEventCacheDuration : _eventsCacheDuration;

      final response = await _apiService.get(url, cacheDuration: cacheDuration);

      dev.log('Response status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        // Log response body length for debugging
        dev.log('Response body length: ${response.body.length} characters');

        // Decode response body
        final Map<String, dynamic> data = jsonDecode(response.body);

        // Extract event URLs
        final List<dynamic> items = data['items'];
        dev.log(
          'Found ${items.length} event items in response for date: $formattedDate',
        );

        if (items.isEmpty) {
          dev.log(
            'WARNING: No events found for league: $league on date: $formattedDate',
          );
          return [];
        }

        final List<String> eventUrls =
            items.map<String>((item) => item['\$ref'] as String).toList();

        // Fetch details for each event (using the same logic as in fetchEventsFromLeague)
        final futures =
            eventUrls.map<Future<Event>>((url) async {
              dev.log('Fetching event details from: $url');

              try {
                // Fetch event data with cache
                final eventResponse = await _apiService.get(url);
                if (eventResponse.statusCode != 200) {
                  throw Exception(
                    'Failed to load event from $url, status: ${eventResponse.statusCode}',
                  );
                }

                final Map<String, dynamic> eventJson = jsonDecode(
                  eventResponse.body,
                );

                // Determine if event is finished for caching purposes
                bool isFinished = _isEventFinished(eventJson);

                // Get competition data
                if (!eventJson.containsKey('competitions') ||
                    eventJson['competitions'].isEmpty) {
                  throw Exception(
                    'No competition data found for event at $url',
                  );
                }

                final competition = eventJson['competitions'][0];

                // Get odds URL
                if (!competition.containsKey('odds') ||
                    competition['odds'] == null ||
                    !competition['odds'].containsKey('\$ref')) {
                  dev.log('No odds data found for event, using default values');
                  // Create mock odds data with default probabilities
                  final mockOddsJson = {
                    'items': [
                      {
                        'provider': {'id': '2000'},
                        'awayTeamOdds': {
                          'odds': {'value': 3.0},
                        },
                        'homeTeamOdds': {
                          'odds': {'value': 2.1},
                        },
                        'drawOdds': {'value': 3.4},
                      },
                    ],
                  };
                  return Event.fromJson(eventJson, mockOddsJson);
                }

                final String oddsUrl = competition['odds']['\$ref'] as String;
                dev.log('Fetching odds from: $oddsUrl');

                // Cache duration based on whether the event is finished
                final Duration oddsCacheDuration =
                    isFinished
                        ? _finishedEventCacheDuration
                        : _upcomingEventCacheDuration;

                // Fetch odds data
                final oddsResponse = await _apiService.get(
                  oddsUrl,
                  cacheDuration: oddsCacheDuration,
                );

                if (oddsResponse.statusCode != 200) {
                  throw Exception(
                    'Failed to load odds from $oddsUrl, status: ${oddsResponse.statusCode}',
                  );
                }

                final Map<String, dynamic> oddsJson = jsonDecode(
                  oddsResponse.body,
                );

                // Create Event object
                return Event.fromJson(eventJson, oddsJson);
              } catch (e, stack) {
                return _errorHandler.handleError<Event>(
                  e,
                  stack,
                  'processing event $url',
                );
              }
            }).toList();

        try {
          final result = await Future.wait(futures);
          dev.log(
            'Successfully fetched ${result.length} events for league: $league on date: $formattedDate',
          );
          return result;
        } catch (e) {
          dev.log('Error during Future.wait: $e');
          rethrow;
        }
      } else {
        throw Exception(
          'Failed to load events for league: $league, date: $formattedDate, status: ${response.statusCode}',
        );
      }
    } catch (e, stack) {
      return _errorHandler.handleError<List<Event>>(
        e,
        stack,
        'fetchEventsByDate',
        defaultValue: [],
      );
    }
  }

  // Helper method to determine if an event is finished
  bool _isEventFinished(Map<String, dynamic> eventJson) {
    // Check competition status if available
    if (eventJson.containsKey('competitions') &&
        eventJson['competitions'] is List &&
        eventJson['competitions'].isNotEmpty) {
      final competition = eventJson['competitions'][0];

      // Check explicit status indicators
      if (competition['status']?['type']?['name'] == "STATUS_FINAL" ||
          competition['status']?['type']?['state'] == "post") {
        return true;
      }

      // Check recap availability
      if (competition['recapAvailable'] == true) {
        return true;
      }

      // Check if live is no longer available
      if (competition['liveAvailable'] == false) {
        return true;
      }
    }

    // Check date - if more than 3 hours in the past, consider finished
    if (eventJson.containsKey('date')) {
      try {
        final eventDate = DateTime.parse(eventJson['date']);
        if (eventDate.isBefore(
          DateTime.now().subtract(const Duration(hours: 3)),
        )) {
          return true;
        }
      } catch (e) {
        // Date parsing error, fall back to default
      }
    }

    return false;
  }
}
