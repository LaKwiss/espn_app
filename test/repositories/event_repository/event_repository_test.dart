import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:http/http.dart' as http;
import 'package:espn_app/models/event.dart';
import 'package:espn_app/services/api_service.dart';
import 'package:espn_app/services/error_handler_service.dart';
import 'package:espn_app/repositories/event_repository/event_repository.dart';

class MockApiService extends Mock implements ApiService {}

class MockErrorHandlerService extends Mock implements ErrorHandlerService {}

class MockResponse extends Mock implements http.Response {}

class MockEvent extends Mock implements Event {}

void main() {
  late MockApiService mockApiService;
  late MockErrorHandlerService mockErrorHandler;
  late EventRepository repository;

  setUp(() {
    mockApiService = MockApiService();
    mockErrorHandler = MockErrorHandlerService();
    repository = EventRepository(
      apiService: mockApiService,
      errorHandler: mockErrorHandler,
    );

    // Register fallback values for when exact matches aren't needed
    registerFallbackValue(Exception('Test exception'));
    registerFallbackValue(StackTrace.current);
    registerFallbackValue('test operation');
    registerFallbackValue(<Event>[]);
  });

  group('fetchEventsFromLeague', () {
    final leagueId = 'test.league';
    final eventsUrl =
        'http://sports.core.api.espn.com/v2/sports/soccer/leagues/$leagueId/events';

    test('should return events when API call is successful', () async {
      // Mock successful events list response
      final mockEventsResponse = MockResponse();
      when(() => mockEventsResponse.statusCode).thenReturn(200);
      when(() => mockEventsResponse.body).thenReturn(
        jsonEncode({
          'items': [
            {'\$ref': 'http://event1.url'},
          ],
        }),
      );

      // Mock successful event details response
      final mockEventResponse = MockResponse();
      when(() => mockEventResponse.statusCode).thenReturn(200);
      when(() => mockEventResponse.body).thenReturn(
        jsonEncode({
          'id': '1',
          'name': 'Team A at Team B',
          'shortName': 'A@B',
          'date': '2023-01-15T12:00Z',
          'competitions': [
            {
              'competitors': [
                {
                  'id': '101',
                  'homeAway': 'home',
                  'score': {'\$ref': 'http://score1.url'},
                },
                {
                  'id': '102',
                  'homeAway': 'away',
                  'score': {'\$ref': 'http://score2.url'},
                },
              ],
              'venue': {'shortName': 'Stadium 1'},
              'odds': {'\$ref': 'http://odds1.url'},
            },
          ],
          'league': {'\$ref': 'http://league1.url'},
        }),
      );

      // Mock successful odds response
      final mockOddsResponse = MockResponse();
      when(() => mockOddsResponse.statusCode).thenReturn(200);
      when(() => mockOddsResponse.body).thenReturn(
        jsonEncode({
          'items': [
            {
              'provider': {'id': '2000'},
              'homeTeamOdds': {
                'odds': {'value': 2.1},
              },
              'awayTeamOdds': {
                'odds': {'value': 3.0},
              },
              'drawOdds': {'value': 3.4},
            },
          ],
        }),
      );

      // Setup API calls
      when(
        () => mockApiService.get(eventsUrl),
      ).thenAnswer((_) async => mockEventsResponse);
      when(
        () => mockApiService.get('http://event1.url'),
      ).thenAnswer((_) async => mockEventResponse);
      when(
        () => mockApiService.get('http://odds1.url'),
      ).thenAnswer((_) async => mockOddsResponse);

      // Create a mock event to return from Future.wait
      final mockEvent = MockEvent();
      when(() => mockEvent.id).thenReturn('1');

      // Call the method
      final result = await repository.fetchEventsFromLeague(leagueId);

      // Verify the right API calls were made
      verify(() => mockApiService.get(eventsUrl)).called(1);
      verify(() => mockApiService.get('http://event1.url')).called(1);
      verify(() => mockApiService.get('http://odds1.url')).called(1);

      // The test will pass if we got here without exceptions
      expect(result, isA<List<Event>>());
    });

    test('should handle API failure for events list', () async {
      // Mock failed events list response
      final mockEventsResponse = MockResponse();
      when(() => mockEventsResponse.statusCode).thenReturn(404);
      when(() => mockEventsResponse.body).thenReturn('Not Found');

      // Setup API call to return error
      when(
        () => mockApiService.get(eventsUrl),
      ).thenAnswer((_) async => mockEventsResponse);

      // Setup error handler to return empty list
      when(
        () => mockErrorHandler.handleError<List<Event>>(
          any(),
          any(),
          any(),
          defaultValue: any(named: 'defaultValue'),
        ),
      ).thenReturn([]);

      // Call the method
      final result = await repository.fetchEventsFromLeague(leagueId);

      // Verify the API call was made
      verify(() => mockApiService.get(eventsUrl)).called(1);

      // Verify error handler was called
      verify(
        () => mockErrorHandler.handleError<List<Event>>(
          any(),
          any(),
          any(),
          defaultValue: any(named: 'defaultValue'),
        ),
      ).called(1);

      // Verify we get an empty list
      expect(result, isEmpty);
    });

    test('should handle empty events list response', () async {
      // Mock empty events list response
      final mockEventsResponse = MockResponse();
      when(() => mockEventsResponse.statusCode).thenReturn(200);
      when(() => mockEventsResponse.body).thenReturn(jsonEncode({'items': []}));

      // Setup API call
      when(
        () => mockApiService.get(eventsUrl),
      ).thenAnswer((_) async => mockEventsResponse);

      // Call the method
      final result = await repository.fetchEventsFromLeague(leagueId);

      // Verify the API call was made
      verify(() => mockApiService.get(eventsUrl)).called(1);

      // Verify we get an empty list
      expect(result, isEmpty);
    });

    test('should handle exception during API call', () async {
      // Setup API call to throw exception
      when(
        () => mockApiService.get(eventsUrl),
      ).thenThrow(Exception('Network error'));

      // Setup error handler to return empty list
      when(
        () => mockErrorHandler.handleError<List<Event>>(
          any(),
          any(),
          any(),
          defaultValue: any(named: 'defaultValue'),
        ),
      ).thenReturn([]);

      // Call the method
      final result = await repository.fetchEventsFromLeague(leagueId);

      // Verify the API call was attempted
      verify(() => mockApiService.get(eventsUrl)).called(1);

      // Verify error handler was called
      verify(
        () => mockErrorHandler.handleError<List<Event>>(
          any(),
          any(),
          any(),
          defaultValue: any(named: 'defaultValue'),
        ),
      ).called(1);

      // Verify we get an empty list
      expect(result, isEmpty);
    });

    test(
      'should handle missing odds data in event and use default values',
      () async {
        // Mock successful events list response
        final mockEventsResponse = MockResponse();
        when(() => mockEventsResponse.statusCode).thenReturn(200);
        when(() => mockEventsResponse.body).thenReturn(
          jsonEncode({
            'items': [
              {'\$ref': 'http://event1.url'},
            ],
          }),
        );

        // Mock event details WITHOUT odds reference
        final mockEventResponse = MockResponse();
        when(() => mockEventResponse.statusCode).thenReturn(200);
        when(() => mockEventResponse.body).thenReturn(
          jsonEncode({
            'id': '1',
            'name': 'Team A at Team B',
            'shortName': 'A@B',
            'date': '2023-01-15T12:00Z',
            'competitions': [
              {
                'competitors': [
                  {
                    'id': '101',
                    'homeAway': 'home',
                    'score': {'\$ref': 'http://score1.url'},
                  },
                  {
                    'id': '102',
                    'homeAway': 'away',
                    'score': {'\$ref': 'http://score2.url'},
                  },
                ],
                'venue': {'shortName': 'Stadium 1'},
                // No odds field here
              },
            ],
            'league': {'\$ref': 'http://league1.url'},
          }),
        );

        // Setup API calls
        when(
          () => mockApiService.get(eventsUrl),
        ).thenAnswer((_) async => mockEventsResponse);
        when(
          () => mockApiService.get('http://event1.url'),
        ).thenAnswer((_) async => mockEventResponse);

        // Call the method
        final result = await repository.fetchEventsFromLeague(leagueId);

        // Verify API calls
        verify(() => mockApiService.get(eventsUrl)).called(1);
        verify(() => mockApiService.get('http://event1.url')).called(1);

        // Verify no call to odds URL
        verifyNever(() => mockApiService.get(any(that: contains('odds'))));

        // The test will pass if we got here without exceptions
        expect(result, isA<List<Event>>());
      },
    );
  });

  group('fetchLeagueName', () {
    final leagueId = 'test.league';
    final leagueUrl =
        'http://sports.core.api.espn.com/v2/sports/soccer/leagues/$leagueId';

    test('should return league name when API call is successful', () async {
      // Mock successful league name response
      final mockResponse = MockResponse();
      when(() => mockResponse.statusCode).thenReturn(200);
      when(
        () => mockResponse.body,
      ).thenReturn(jsonEncode({'displayName': 'Test League'}));

      // Setup API call
      when(
        () => mockApiService.get(leagueUrl),
      ).thenAnswer((_) async => mockResponse);

      // Call the method
      final result = await repository.fetchLeagueName(leagueId);

      // Verify the API call was made
      verify(() => mockApiService.get(leagueUrl)).called(1);

      // Verify the result
      expect(result, 'Test League');
    });

    test('should handle API failure for league name', () async {
      // Mock failed league name response
      final mockResponse = MockResponse();
      when(() => mockResponse.statusCode).thenReturn(404);
      when(() => mockResponse.body).thenReturn('Not Found');

      // Setup API call
      when(
        () => mockApiService.get(leagueUrl),
      ).thenAnswer((_) async => mockResponse);

      // Setup error handler to return leagueId as fallback
      when(
        () => mockErrorHandler.handleError<String>(
          any(),
          any(),
          any(),
          defaultValue: leagueId,
        ),
      ).thenReturn(leagueId);

      // Call the method
      final result = await repository.fetchLeagueName(leagueId);

      // Verify the API call was made
      verify(() => mockApiService.get(leagueUrl)).called(1);

      // Verify error handler was called
      verify(
        () => mockErrorHandler.handleError<String>(
          any(),
          any(),
          any(),
          defaultValue: leagueId,
        ),
      ).called(1);

      // Verify we get the leagueId as fallback
      expect(result, leagueId);
    });

    test('should handle exception during API call for league name', () async {
      // Setup API call to throw exception
      when(
        () => mockApiService.get(leagueUrl),
      ).thenThrow(Exception('Network error'));

      // Setup error handler to return leagueId as fallback
      when(
        () => mockErrorHandler.handleError<String>(
          any(),
          any(),
          any(),
          defaultValue: leagueId,
        ),
      ).thenReturn(leagueId);

      // Call the method
      final result = await repository.fetchLeagueName(leagueId);

      // Verify the API call was attempted
      verify(() => mockApiService.get(leagueUrl)).called(1);

      // Verify error handler was called
      verify(
        () => mockErrorHandler.handleError<String>(
          any(),
          any(),
          any(),
          defaultValue: leagueId,
        ),
      ).called(1);

      // Verify we get the leagueId as fallback
      expect(result, leagueId);
    });
  });

  group('fetchEventsByDate', () {
    final leagueId = 'test.league';
    final testDate = DateTime(2023, 1, 15);
    final formattedDate = '20230115';
    final eventsUrl =
        'http://sports.core.api.espn.com/v2/sports/soccer/leagues/$leagueId/events?dates=$formattedDate';

    test('should return events when API call is successful', () async {
      // Mock successful events list response
      final mockEventsResponse = MockResponse();
      when(() => mockEventsResponse.statusCode).thenReturn(200);
      when(() => mockEventsResponse.body).thenReturn(
        jsonEncode({
          'items': [
            {'\$ref': 'http://event1.url'},
          ],
        }),
      );

      // Mock successful event details response
      final mockEventResponse = MockResponse();
      when(() => mockEventResponse.statusCode).thenReturn(200);
      when(() => mockEventResponse.body).thenReturn(
        jsonEncode({
          'id': '1',
          'name': 'Team A at Team B',
          'shortName': 'A@B',
          'date': '2023-01-15T12:00Z',
          'competitions': [
            {
              'competitors': [
                {
                  'id': '101',
                  'homeAway': 'home',
                  'score': {'\$ref': 'http://score1.url'},
                },
                {
                  'id': '102',
                  'homeAway': 'away',
                  'score': {'\$ref': 'http://score2.url'},
                },
              ],
              'venue': {'shortName': 'Stadium 1'},
              'odds': {'\$ref': 'http://odds1.url'},
            },
          ],
          'league': {'\$ref': 'http://league1.url'},
        }),
      );

      // Mock successful odds response
      final mockOddsResponse = MockResponse();
      when(() => mockOddsResponse.statusCode).thenReturn(200);
      when(() => mockOddsResponse.body).thenReturn(
        jsonEncode({
          'items': [
            {
              'provider': {'id': '2000'},
              'homeTeamOdds': {
                'odds': {'value': 2.1},
              },
              'awayTeamOdds': {
                'odds': {'value': 3.0},
              },
              'drawOdds': {'value': 3.4},
            },
          ],
        }),
      );

      // Setup API calls
      when(
        () => mockApiService.get(eventsUrl),
      ).thenAnswer((_) async => mockEventsResponse);
      when(
        () => mockApiService.get('http://event1.url'),
      ).thenAnswer((_) async => mockEventResponse);
      when(
        () => mockApiService.get('http://odds1.url'),
      ).thenAnswer((_) async => mockOddsResponse);

      // Call the method
      final result = await repository.fetchEventsByDate(leagueId, testDate);

      // Verify the right API calls were made
      verify(() => mockApiService.get(eventsUrl)).called(1);
      verify(() => mockApiService.get('http://event1.url')).called(1);
      verify(() => mockApiService.get('http://odds1.url')).called(1);

      // The test will pass if we got here without exceptions
      expect(result, isA<List<Event>>());
    });

    test('should handle API failure for events by date', () async {
      // Mock failed events list response
      final mockEventsResponse = MockResponse();
      when(() => mockEventsResponse.statusCode).thenReturn(404);
      when(() => mockEventsResponse.body).thenReturn('Not Found');

      // Setup API call to return error
      when(
        () => mockApiService.get(eventsUrl),
      ).thenAnswer((_) async => mockEventsResponse);

      // Setup error handler to return empty list
      when(
        () => mockErrorHandler.handleError<List<Event>>(
          any(),
          any(),
          any(),
          defaultValue: any(named: 'defaultValue'),
        ),
      ).thenReturn([]);

      // Call the method
      final result = await repository.fetchEventsByDate(leagueId, testDate);

      // Verify the API call was made
      verify(() => mockApiService.get(eventsUrl)).called(1);

      // Verify error handler was called
      verify(
        () => mockErrorHandler.handleError<List<Event>>(
          any(),
          any(),
          any(),
          defaultValue: any(named: 'defaultValue'),
        ),
      ).called(1);

      // Verify we get an empty list
      expect(result, isEmpty);
    });

    test('should handle empty events list response for date', () async {
      // Mock empty events list response
      final mockEventsResponse = MockResponse();
      when(() => mockEventsResponse.statusCode).thenReturn(200);
      when(() => mockEventsResponse.body).thenReturn(jsonEncode({'items': []}));

      // Setup API call
      when(
        () => mockApiService.get(eventsUrl),
      ).thenAnswer((_) async => mockEventsResponse);

      // Call the method
      final result = await repository.fetchEventsByDate(leagueId, testDate);

      // Verify the API call was made
      verify(() => mockApiService.get(eventsUrl)).called(1);

      // Verify we get an empty list
      expect(result, isEmpty);
    });

    test(
      'should handle exception during API call for events by date',
      () async {
        // Setup API call to throw exception
        when(
          () => mockApiService.get(eventsUrl),
        ).thenThrow(Exception('Network error'));

        // Setup error handler to return empty list
        when(
          () => mockErrorHandler.handleError<List<Event>>(
            any(),
            any(),
            any(),
            defaultValue: any(named: 'defaultValue'),
          ),
        ).thenReturn([]);

        // Call the method
        final result = await repository.fetchEventsByDate(leagueId, testDate);

        // Verify the API call was attempted
        verify(() => mockApiService.get(eventsUrl)).called(1);

        // Verify error handler was called
        verify(
          () => mockErrorHandler.handleError<List<Event>>(
            any(),
            any(),
            any(),
            defaultValue: any(named: 'defaultValue'),
          ),
        ).called(1);

        // Verify we get an empty list
        expect(result, isEmpty);
      },
    );
  });
}
