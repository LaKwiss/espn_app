import 'dart:convert';
import 'dart:developer' as dev;
import 'package:http/http.dart' as http;
import 'package:espn_app/class/event.dart';

class EventRepository {
  /// Fetches events for a specific league with enhanced debugging
  static Future<List<Event>> fetchEventsFromLeague(String league) async {
    dev.log('Starting fetchEventsFromLeague for: $league');

    final url =
        'http://sports.core.api.espn.com/v2/sports/soccer/leagues/$league/events';
    dev.log('Fetching from URL: $url');

    try {
      final response = await http.get(Uri.parse(url));

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
                // Fetch event data
                final eventResponse = await http.get(Uri.parse(url));
                if (eventResponse.statusCode != 200) {
                  throw Exception(
                    'Failed to load event from $url, status: ${eventResponse.statusCode}',
                  );
                }

                final Map<String, dynamic> eventJson = jsonDecode(
                  eventResponse.body,
                );

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

                // Fetch odds data
                final oddsResponse = await http.get(Uri.parse(oddsUrl));
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
                dev.log('Error processing event $url: $e');
                dev.log('Stack trace: $stack');
                rethrow; // Allow the caller to handle this
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
      dev.log('Error in fetchEventsFromLeague: $e');
      dev.log('Stack trace: $stack');
      throw Exception('Failed to fetch events: $e');
    }
  }

  /// Fetches the league name from its endpoint
  static Future<String> fetchLeagueName(String leagueName) async {
    dev.log('Fetching league name for: $leagueName');

    try {
      final response = await http.get(
        Uri.parse(
          'http://sports.core.api.espn.com/v2/sports/soccer/leagues/$leagueName',
        ),
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
    } catch (e) {
      dev.log('Exception fetching league name: $e');
      throw Exception('Failed to fetch league name: $e');
    }
  }

  /// Fetches events for a specific date and league
  static Future<List<Event>> fetchEventsByDate(
    String league,
    DateTime date,
  ) async {
    final formattedDate =
        '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
    dev.log('Fetching events for league: $league on date: $formattedDate');

    final url =
        'http://sports.core.api.espn.com/v2/sports/soccer/leagues/$league/events?dates=$formattedDate';
    dev.log('Fetching from URL: $url');

    try {
      final response = await http.get(Uri.parse(url));

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
                // Fetch event data
                final eventResponse = await http.get(Uri.parse(url));
                if (eventResponse.statusCode != 200) {
                  throw Exception(
                    'Failed to load event from $url, status: ${eventResponse.statusCode}',
                  );
                }

                final Map<String, dynamic> eventJson = jsonDecode(
                  eventResponse.body,
                );

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

                // Fetch odds data
                final oddsResponse = await http.get(Uri.parse(oddsUrl));
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
                dev.log('Error processing event $url: $e');
                dev.log('Stack trace: $stack');
                rethrow; // Allow the caller to handle this
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
      dev.log('Error in fetchEventsByDate: $e');
      dev.log('Stack trace: $stack');
      throw Exception('Failed to fetch events: $e');
    }
  }
}
