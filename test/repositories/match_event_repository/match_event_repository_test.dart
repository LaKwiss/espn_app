import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:http/http.dart' as http;
import 'package:espn_app/services/api_service.dart';
import 'package:espn_app/services/error_handler_service.dart';
import 'package:espn_app/models/match_event.dart';
import 'package:espn_app/repositories/match_event_repository/match_event_repository.dart';

class MockApiService extends Mock implements ApiService {}

class MockErrorHandlerService extends Mock implements ErrorHandlerService {}

class MockResponse extends Mock implements http.Response {}

void main() {
  late MockApiService mockApiService;
  late MockErrorHandlerService mockErrorHandler;
  late MatchEventRepository repository;

  setUp(() {
    mockApiService = MockApiService();
    mockErrorHandler = MockErrorHandlerService();
    repository = MatchEventRepository(
      apiService: mockApiService,
      errorHandler: mockErrorHandler,
    );

    // Register fallback values for when exact matches aren't needed
    registerFallbackValue(Exception('Test exception'));
    registerFallbackValue(StackTrace.current);
    registerFallbackValue('test operation');
    registerFallbackValue(<MatchEvent>[]);
  });

  group('fetchMatchEvents', () {
    final matchId = '123456';
    final leagueId = 'esp.1';
    final matchEventsUrl =
        'http://sports.core.api.espn.com/v2/sports/soccer/leagues/$leagueId/events/$matchId/competitions/$matchId/plays?limit=1000';

    test('should return match events when API call is successful', () async {
      // Setup mock team IDs response for the internal call
      when(
        () => mockApiService.get(
          'http://sports.core.api.espn.com/v2/sports/soccer/leagues/$leagueId/events/$matchId?lang=en&region=us',
        ),
      ).thenAnswer((_) async {
        final mockTeamResponse = MockResponse();
        when(() => mockTeamResponse.statusCode).thenReturn(200);
        when(() => mockTeamResponse.body).thenReturn(
          jsonEncode({
            'competitions': [
              {
                'competitors': [
                  {'id': '1001', 'homeAway': 'home'},
                  {'id': '2002', 'homeAway': 'away'},
                ],
              },
            ],
          }),
        );
        return mockTeamResponse;
      });

      // Mock successful match events response
      final mockEventsResponse = MockResponse();
      when(() => mockEventsResponse.statusCode).thenReturn(200);
      when(() => mockEventsResponse.body).thenReturn(
        jsonEncode({
          'items': [
            {
              'id': 'event1',
              'type': {'id': '1', 'text': 'Goal'},
              'text': 'Goal! Player 1',
              'alternativeText': 'But! Joueur 1',
              'clock': {'value': 1380, 'displayValue': '23\''},
              'period': {'number': 1},
              'awayScore': 1,
              'homeScore': 0,
              'scoringPlay': true,
              'priority': true,
              'wallclock': '2023-01-15T12:23:00Z',
              'team': {'\$ref': 'http://team/2002'},
              'participants': [],
            },
            {
              'id': 'event2',
              'type': {'id': '2', 'text': 'Yellow Card'},
              'text': 'Yellow Card for Player 2',
              'alternativeText': 'Carton jaune pour Joueur 2',
              'clock': {'value': 2280, 'displayValue': '38\''},
              'period': {'number': 1},
              'awayScore': 1,
              'homeScore': 0,
              'scoringPlay': false,
              'priority': false,
              'wallclock': '2023-01-15T12:38:00Z',
              'team': {'\$ref': 'http://team/1001'},
              'participants': [],
            },
          ],
        }),
      );

      // Setup API call
      when(
        () => mockApiService.get(matchEventsUrl),
      ).thenAnswer((_) async => mockEventsResponse);

      // Call the method
      final result = await repository.fetchMatchEvents(
        matchId: matchId,
        leagueId: leagueId,
      );

      // Verify the API calls were made
      verify(() => mockApiService.get(matchEventsUrl)).called(1);
      verify(
        () => mockApiService.get(
          'http://sports.core.api.espn.com/v2/sports/soccer/leagues/$leagueId/events/$matchId?lang=en&region=us',
        ),
      ).called(1);

      // Verify the result
      expect(result, isA<List<MatchEvent>>());
      expect(result.length, 2);
      expect(result[0].type, MatchEventType.goal);
      expect(result[1].type, MatchEventType.yellowCard);
    });

    test('should return mock events when API call fails', () async {
      // Setup mock team IDs response for the internal call
      when(
        () => mockApiService.get(
          'http://sports.core.api.espn.com/v2/sports/soccer/leagues/$leagueId/events/$matchId?lang=en&region=us',
        ),
      ).thenAnswer((_) async {
        final mockTeamResponse = MockResponse();
        when(() => mockTeamResponse.statusCode).thenReturn(200);
        when(() => mockTeamResponse.body).thenReturn(
          jsonEncode({
            'competitions': [
              {
                'competitors': [
                  {'id': '1001', 'homeAway': 'home'},
                  {'id': '2002', 'homeAway': 'away'},
                ],
              },
            ],
          }),
        );
        return mockTeamResponse;
      });

      // Mock failed events response
      final mockEventsResponse = MockResponse();
      when(() => mockEventsResponse.statusCode).thenReturn(404);
      when(() => mockEventsResponse.body).thenReturn('Not Found');

      // Setup API call
      when(
        () => mockApiService.get(matchEventsUrl),
      ).thenAnswer((_) async => mockEventsResponse);

      // Call the method
      final result = await repository.fetchMatchEvents(
        matchId: matchId,
        leagueId: leagueId,
      );

      // Verify the API calls were made
      verify(() => mockApiService.get(matchEventsUrl)).called(1);
      verify(
        () => mockApiService.get(
          'http://sports.core.api.espn.com/v2/sports/soccer/leagues/$leagueId/events/$matchId?lang=en&region=us',
        ),
      ).called(1);

      // Verify the result is mock events
      expect(result, isA<List<MatchEvent>>());
      expect(result.length, 4); // Default mock events length
      expect(result[0].type, MatchEventType.kickoff);
      expect(result[1].type, MatchEventType.goal);
    });

    test('should return mock events when API response has no items', () async {
      // Setup mock team IDs response for the internal call
      when(
        () => mockApiService.get(
          'http://sports.core.api.espn.com/v2/sports/soccer/leagues/$leagueId/events/$matchId?lang=en&region=us',
        ),
      ).thenAnswer((_) async {
        final mockTeamResponse = MockResponse();
        when(() => mockTeamResponse.statusCode).thenReturn(200);
        when(() => mockTeamResponse.body).thenReturn(
          jsonEncode({
            'competitions': [
              {
                'competitors': [
                  {'id': '1001', 'homeAway': 'home'},
                  {'id': '2002', 'homeAway': 'away'},
                ],
              },
            ],
          }),
        );
        return mockTeamResponse;
      });

      // Mock empty items response
      final mockEventsResponse = MockResponse();
      when(() => mockEventsResponse.statusCode).thenReturn(200);
      when(() => mockEventsResponse.body).thenReturn(jsonEncode({'items': []}));

      // Setup API call
      when(
        () => mockApiService.get(matchEventsUrl),
      ).thenAnswer((_) async => mockEventsResponse);

      // Call the method
      final result = await repository.fetchMatchEvents(
        matchId: matchId,
        leagueId: leagueId,
      );

      // Verify the API calls were made
      verify(() => mockApiService.get(matchEventsUrl)).called(1);
      verify(
        () => mockApiService.get(
          'http://sports.core.api.espn.com/v2/sports/soccer/leagues/$leagueId/events/$matchId?lang=en&region=us',
        ),
      ).called(1);

      // Verify the result is mock events
      expect(result, isA<List<MatchEvent>>());
      expect(result.length, 4); // Default mock events length
    });

    test('should handle exception during API call', () async {
      // Setup mock team IDs response for the internal call
      when(
        () => mockApiService.get(
          'http://sports.core.api.espn.com/v2/sports/soccer/leagues/$leagueId/events/$matchId?lang=en&region=us',
        ),
      ).thenAnswer((_) async {
        final mockTeamResponse = MockResponse();
        when(() => mockTeamResponse.statusCode).thenReturn(200);
        when(() => mockTeamResponse.body).thenReturn(
          jsonEncode({
            'competitions': [
              {
                'competitors': [
                  {'id': '1001', 'homeAway': 'home'},
                  {'id': '2002', 'homeAway': 'away'},
                ],
              },
            ],
          }),
        );
        return mockTeamResponse;
      });

      // Setup API call to throw exception
      when(
        () => mockApiService.get(matchEventsUrl),
      ).thenThrow(Exception('Network error'));

      // Setup error handler to return mock events
      when(
        () => mockErrorHandler.handleError<List<MatchEvent>>(
          any(),
          any(),
          any(),
          defaultValue: any(named: 'defaultValue'),
        ),
      ).thenAnswer((invocation) {
        // Return the defaultValue that was passed to the handler
        return invocation.namedArguments[const Symbol('defaultValue')]
            as List<MatchEvent>;
      });

      // Call the method
      final result = await repository.fetchMatchEvents(
        matchId: matchId,
        leagueId: leagueId,
      );

      // Verify the API call was attempted
      verify(() => mockApiService.get(matchEventsUrl)).called(1);

      // Verify error handler was called
      verify(
        () => mockErrorHandler.handleError<List<MatchEvent>>(
          any(),
          any(),
          any(),
          defaultValue: any(named: 'defaultValue'),
        ),
      ).called(1);

      // Verify the result is mock events
      expect(result, isA<List<MatchEvent>>());
      expect(result.length, 4); // Default mock events length
    });

    test('should handle missing items field in response', () async {
      // Setup mock team IDs response for the internal call
      when(
        () => mockApiService.get(
          'http://sports.core.api.espn.com/v2/sports/soccer/leagues/$leagueId/events/$matchId?lang=en&region=us',
        ),
      ).thenAnswer((_) async {
        final mockTeamResponse = MockResponse();
        when(() => mockTeamResponse.statusCode).thenReturn(200);
        when(() => mockTeamResponse.body).thenReturn(
          jsonEncode({
            'competitions': [
              {
                'competitors': [
                  {'id': '1001', 'homeAway': 'home'},
                  {'id': '2002', 'homeAway': 'away'},
                ],
              },
            ],
          }),
        );
        return mockTeamResponse;
      });

      // Mock response without items field
      final mockEventsResponse = MockResponse();
      when(() => mockEventsResponse.statusCode).thenReturn(200);
      when(() => mockEventsResponse.body).thenReturn(
        jsonEncode({
          // No items field
          'someOtherField': 'value',
        }),
      );

      // Setup API call
      when(
        () => mockApiService.get(matchEventsUrl),
      ).thenAnswer((_) async => mockEventsResponse);

      // Call the method
      final result = await repository.fetchMatchEvents(
        matchId: matchId,
        leagueId: leagueId,
      );

      // Verify the API calls were made
      verify(() => mockApiService.get(matchEventsUrl)).called(1);

      // Verify the result is mock events
      expect(result, isA<List<MatchEvent>>());
      expect(result.length, 4); // Default mock events length
    });
  });

  group('fetchLiveMatchEvents', () {
    final matchId = '123456';
    final leagueId = 'esp.1';

    test('should call fetchMatchEvents internally', () async {
      // Setup mock fetchMatchEvents to return empty list
      final mockEvents = <MatchEvent>[];
      when(() => mockApiService.get(any())).thenAnswer((_) async {
        final mockResponse = MockResponse();
        when(() => mockResponse.statusCode).thenReturn(200);
        when(() => mockResponse.body).thenReturn('{}');
        return mockResponse;
      });

      // Setup mock error handler for any API issues
      when(
        () => mockErrorHandler.handleError<List<MatchEvent>>(
          any(),
          any(),
          any(),
          defaultValue: any(named: 'defaultValue'),
        ),
      ).thenReturn(mockEvents);

      // Call the method
      final result = await repository.fetchLiveMatchEvents(
        matchId: matchId,
        leagueId: leagueId,
      );

      // Verify it ultimately makes the same API call as fetchMatchEvents
      verify(
        () => mockApiService.get(
          'http://sports.core.api.espn.com/v2/sports/soccer/leagues/$leagueId/events/$matchId/competitions/$matchId/plays?limit=1000',
        ),
      ).called(1);

      // Verify we get a list (even if empty due to our mocks)
      expect(result, isA<List<MatchEvent>>());
    });
  });

  group('fetchTeamIds', () {
    final matchId = '123456';
    final leagueId = 'esp.1';
    final teamInfoUrl =
        'http://sports.core.api.espn.com/v2/sports/soccer/leagues/$leagueId/events/$matchId?lang=en&region=us';

    test('should return team IDs when API call is successful', () async {
      // Mock successful response
      final mockResponse = MockResponse();
      when(() => mockResponse.statusCode).thenReturn(200);
      when(() => mockResponse.body).thenReturn(
        jsonEncode({
          'competitions': [
            {
              'competitors': [
                {'id': '1001', 'homeAway': 'home'},
                {'id': '2002', 'homeAway': 'away'},
              ],
            },
          ],
        }),
      );

      // Setup API call
      when(
        () => mockApiService.get(teamInfoUrl),
      ).thenAnswer((_) async => mockResponse);

      // Call the method
      final result = await repository.fetchTeamIds(matchId, leagueId);

      // Verify the API call was made
      verify(() => mockApiService.get(teamInfoUrl)).called(1);

      // Verify the result
      expect(result.$1, '2002'); // Away team ID
      expect(result.$2, '1001'); // Home team ID
    });

    test('should handle API failure', () async {
      // Mock failed response
      final mockResponse = MockResponse();
      when(() => mockResponse.statusCode).thenReturn(404);
      when(() => mockResponse.body).thenReturn('Not Found');

      // Setup API call
      when(
        () => mockApiService.get(teamInfoUrl),
      ).thenAnswer((_) async => mockResponse);

      // Setup error handler to return default IDs
      when(
        () => mockErrorHandler.handleError<(String, String)>(
          any(),
          any(),
          any(),
          defaultValue: any(named: 'defaultValue'),
        ),
      ).thenReturn(('0', '0'));

      // Call the method
      final result = await repository.fetchTeamIds(matchId, leagueId);

      // Verify the API call was made
      verify(() => mockApiService.get(teamInfoUrl)).called(1);

      // Verify error handler was called
      verify(
        () => mockErrorHandler.handleError<(String, String)>(
          any(),
          any(),
          any(),
          defaultValue: any(named: 'defaultValue'),
        ),
      ).called(1);

      // Verify we get the default IDs
      expect(result.$1, '0'); // Default away team ID
      expect(result.$2, '0'); // Default home team ID
    });

    test('should handle missing competitions field', () async {
      // Mock response with missing competitions
      final mockResponse = MockResponse();
      when(() => mockResponse.statusCode).thenReturn(200);
      when(() => mockResponse.body).thenReturn(
        jsonEncode({
          // No competitions field
        }),
      );

      // Setup API call
      when(
        () => mockApiService.get(teamInfoUrl),
      ).thenAnswer((_) async => mockResponse);

      // Setup error handler to return default IDs
      when(
        () => mockErrorHandler.handleError<(String, String)>(
          any(),
          any(),
          any(),
          defaultValue: any(named: 'defaultValue'),
        ),
      ).thenReturn(('0', '0'));

      // Call the method
      final result = await repository.fetchTeamIds(matchId, leagueId);

      // Verify the API call was made
      verify(() => mockApiService.get(teamInfoUrl)).called(1);

      // Verify we get the default IDs due to exception handling
      expect(result.$1, '0');
      expect(result.$2, '0');
    });

    test('should handle missing competitors field', () async {
      // Mock response with missing competitors
      final mockResponse = MockResponse();
      when(() => mockResponse.statusCode).thenReturn(200);
      when(() => mockResponse.body).thenReturn(
        jsonEncode({
          'competitions': [
            {
              // No competitors field
            },
          ],
        }),
      );

      // Setup API call
      when(
        () => mockApiService.get(teamInfoUrl),
      ).thenAnswer((_) async => mockResponse);

      // Setup error handler to return default IDs
      when(
        () => mockErrorHandler.handleError<(String, String)>(
          any(),
          any(),
          any(),
          defaultValue: any(named: 'defaultValue'),
        ),
      ).thenReturn(('0', '0'));

      // Call the method
      final result = await repository.fetchTeamIds(matchId, leagueId);

      // Verify the API call was made
      verify(() => mockApiService.get(teamInfoUrl)).called(1);

      // Verify we get the default IDs due to exception handling
      expect(result.$1, '0');
      expect(result.$2, '0');
    });

    test('should handle insufficient competitors', () async {
      // Mock response with only one competitor
      final mockResponse = MockResponse();
      when(() => mockResponse.statusCode).thenReturn(200);
      when(() => mockResponse.body).thenReturn(
        jsonEncode({
          'competitions': [
            {
              'competitors': [
                {'id': '1001', 'homeAway': 'home'},
                // Only one competitor
              ],
            },
          ],
        }),
      );

      // Setup API call
      when(
        () => mockApiService.get(teamInfoUrl),
      ).thenAnswer((_) async => mockResponse);

      // Setup error handler to return default IDs
      when(
        () => mockErrorHandler.handleError<(String, String)>(
          any(),
          any(),
          any(),
          defaultValue: any(named: 'defaultValue'),
        ),
      ).thenReturn(('0', '0'));

      // Call the method
      final result = await repository.fetchTeamIds(matchId, leagueId);

      // Verify the API call was made
      verify(() => mockApiService.get(teamInfoUrl)).called(1);

      // Verify we get the default IDs due to exception handling
      expect(result.$1, '0');
      expect(result.$2, '0');
    });

    test('should handle exception during API call', () async {
      // Setup API call to throw exception
      when(
        () => mockApiService.get(teamInfoUrl),
      ).thenThrow(Exception('Network error'));

      // Setup error handler to return default IDs
      when(
        () => mockErrorHandler.handleError<(String, String)>(
          any(),
          any(),
          any(),
          defaultValue: any(named: 'defaultValue'),
        ),
      ).thenReturn(('0', '0'));

      // Call the method
      final result = await repository.fetchTeamIds(matchId, leagueId);

      // Verify the API call was attempted
      verify(() => mockApiService.get(teamInfoUrl)).called(1);

      // Verify error handler was called
      verify(
        () => mockErrorHandler.handleError<(String, String)>(
          any(),
          any(),
          any(),
          defaultValue: any(named: 'defaultValue'),
        ),
      ).called(1);

      // Verify we get the default IDs
      expect(result.$1, '0');
      expect(result.$2, '0');
    });
  });
}
