import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:http/http.dart' as http;
import 'package:espn_app/services/api_service.dart';
import 'package:espn_app/services/error_handler_service.dart';
import 'package:espn_app/repositories/league_picture_repository/league_picture_repository.dart';

class MockApiService extends Mock implements ApiService {}

class MockErrorHandlerService extends Mock implements ErrorHandlerService {}

class MockResponse extends Mock implements http.Response {}

void main() {
  late MockApiService mockApiService;
  late MockErrorHandlerService mockErrorHandler;
  late LeaguePictureRepository repository;

  setUp(() {
    mockApiService = MockApiService();
    mockErrorHandler = MockErrorHandlerService();
    repository = LeaguePictureRepository(
      apiService: mockApiService,
      errorHandler: mockErrorHandler,
    );

    // Register fallback values for when exact matches aren't needed
    registerFallbackValue(Exception('Test exception'));
    registerFallbackValue(StackTrace.current);
    registerFallbackValue('test operation');
    registerFallbackValue('default url');
  });

  group('getUrlByLeagueCode', () {
    final leagueCode = 'esp.1';
    final leagueUrl =
        'http://sports.core.api.espn.com/v2/sports/soccer/leagues/$leagueCode';
    final defaultLogoUrl =
        'https://a.espncdn.com/i/leaguelogos/soccer/500/2.png';

    test('should return logo URL when API call is successful', () async {
      // Mock successful response
      final mockResponse = MockResponse();
      when(() => mockResponse.statusCode).thenReturn(200);
      when(() => mockResponse.body).thenReturn(
        jsonEncode({
          'id': leagueCode,
          'name': 'La Liga',
          'logos': [
            {
              'href':
                  'https://a.espncdn.com/i/leaguelogos/soccer/500/15-light.png',
              'width': 500,
              'height': 500,
            },
            {
              'href': 'https://a.espncdn.com/i/leaguelogos/soccer/500/15.png',
              'width': 500,
              'height': 500,
            },
          ],
        }),
      );

      // Setup API call
      when(
        () => mockApiService.get(leagueUrl),
      ).thenAnswer((_) async => mockResponse);

      // Call the method
      final result = await repository.getUrlByLeagueCode(leagueCode);

      // Verify the API call was made
      verify(() => mockApiService.get(leagueUrl)).called(1);

      // Verify the result
      expect(result, 'https://a.espncdn.com/i/leaguelogos/soccer/500/15.png');
    });

    test('should handle API failure', () async {
      // Mock failed response
      final mockResponse = MockResponse();
      when(() => mockResponse.statusCode).thenReturn(404);
      when(() => mockResponse.body).thenReturn('Not Found');

      // Setup API call
      when(
        () => mockApiService.get(leagueUrl),
      ).thenAnswer((_) async => mockResponse);

      // Setup error handler to return default URL
      when(
        () => mockErrorHandler.handleError<String>(
          any(),
          any(),
          any(),
          defaultValue: any(named: 'defaultValue'),
        ),
      ).thenReturn(defaultLogoUrl);

      // Call the method
      final result = await repository.getUrlByLeagueCode(leagueCode);

      // Verify the API call was made
      verify(() => mockApiService.get(leagueUrl)).called(1);

      // Verify error handler was called
      verify(
        () => mockErrorHandler.handleError<String>(
          any(),
          any(),
          any(),
          defaultValue: any(named: 'defaultValue'),
        ),
      ).called(1);

      // Verify we get the default URL
      expect(result, defaultLogoUrl);
    });

    test('should handle exception during API call', () async {
      // Setup API call to throw exception
      when(
        () => mockApiService.get(leagueUrl),
      ).thenThrow(Exception('Network error'));

      // Setup error handler to return default URL
      when(
        () => mockErrorHandler.handleError<String>(
          any(),
          any(),
          any(),
          defaultValue: any(named: 'defaultValue'),
        ),
      ).thenReturn(defaultLogoUrl);

      // Call the method
      final result = await repository.getUrlByLeagueCode(leagueCode);

      // Verify the API call was attempted
      verify(() => mockApiService.get(leagueUrl)).called(1);

      // Verify error handler was called
      verify(
        () => mockErrorHandler.handleError<String>(
          any(),
          any(),
          any(),
          defaultValue: any(named: 'defaultValue'),
        ),
      ).called(1);

      // Verify we get the default URL
      expect(result, defaultLogoUrl);
    });

    test('should handle missing logos array in response', () async {
      // Mock response with missing logos array
      final mockResponse = MockResponse();
      when(() => mockResponse.statusCode).thenReturn(200);
      when(() => mockResponse.body).thenReturn(
        jsonEncode({
          'id': leagueCode,
          'name': 'La Liga',
          // No logos array
        }),
      );

      // Setup API call
      when(
        () => mockApiService.get(leagueUrl),
      ).thenAnswer((_) async => mockResponse);

      // Setup error handler to return default URL
      when(
        () => mockErrorHandler.handleError<String>(
          any(),
          any(),
          any(),
          defaultValue: any(named: 'defaultValue'),
        ),
      ).thenReturn(defaultLogoUrl);

      // Call the method - this should throw an exception that gets handled
      final result = await repository.getUrlByLeagueCode(leagueCode);

      // Verify the API call was made
      verify(() => mockApiService.get(leagueUrl)).called(1);

      // Verify error handler was called
      verify(
        () => mockErrorHandler.handleError<String>(
          any(),
          any(),
          any(),
          defaultValue: any(named: 'defaultValue'),
        ),
      ).called(1);

      // Verify we get the default URL
      expect(result, defaultLogoUrl);
    });

    test('should handle insufficient logos in array', () async {
      // Mock response with insufficient logos
      final mockResponse = MockResponse();
      when(() => mockResponse.statusCode).thenReturn(200);
      when(() => mockResponse.body).thenReturn(
        jsonEncode({
          'id': leagueCode,
          'name': 'La Liga',
          'logos': [
            {
              'href':
                  'https://a.espncdn.com/i/leaguelogos/soccer/500/15-light.png',
              'width': 500,
              'height': 500,
            },
            // Only one logo, but code expects at least two
          ],
        }),
      );

      // Setup API call
      when(
        () => mockApiService.get(leagueUrl),
      ).thenAnswer((_) async => mockResponse);

      // Setup error handler to return default URL
      when(
        () => mockErrorHandler.handleError<String>(
          any(),
          any(),
          any(),
          defaultValue: any(named: 'defaultValue'),
        ),
      ).thenReturn(defaultLogoUrl);

      // Call the method - this should throw an exception that gets handled
      final result = await repository.getUrlByLeagueCode(leagueCode);

      // Verify the API call was made
      verify(() => mockApiService.get(leagueUrl)).called(1);

      // Verify error handler was called
      verify(
        () => mockErrorHandler.handleError<String>(
          any(),
          any(),
          any(),
          defaultValue: any(named: 'defaultValue'),
        ),
      ).called(1);

      // Verify we get the default URL
      expect(result, defaultLogoUrl);
    });

    test('should handle empty league code', () async {
      // Setup for empty league code
      final emptyLeagueUrl =
          'http://sports.core.api.espn.com/v2/sports/soccer/leagues/';

      // Mock response for empty league code
      final mockResponse = MockResponse();
      when(() => mockResponse.statusCode).thenReturn(404);
      when(() => mockResponse.body).thenReturn('Not Found');

      // Setup API call
      when(
        () => mockApiService.get(emptyLeagueUrl),
      ).thenAnswer((_) async => mockResponse);

      // Setup error handler to return default URL
      when(
        () => mockErrorHandler.handleError<String>(
          any(),
          any(),
          any(),
          defaultValue: any(named: 'defaultValue'),
        ),
      ).thenReturn(defaultLogoUrl);

      // Call the method with empty league code
      final result = await repository.getUrlByLeagueCode('');

      // Verify the API call was made
      verify(() => mockApiService.get(emptyLeagueUrl)).called(1);

      // Verify error handler was called
      verify(
        () => mockErrorHandler.handleError<String>(
          any(),
          any(),
          any(),
          defaultValue: any(named: 'defaultValue'),
        ),
      ).called(1);

      // Verify we get the default URL
      expect(result, defaultLogoUrl);
    });

    test('should handle malformed JSON response', () async {
      // Mock response with malformed JSON
      final mockResponse = MockResponse();
      when(() => mockResponse.statusCode).thenReturn(200);
      when(() => mockResponse.body).thenReturn('{ malformed json }');

      // Setup API call
      when(
        () => mockApiService.get(leagueUrl),
      ).thenAnswer((_) async => mockResponse);

      // Setup error handler to return default URL
      when(
        () => mockErrorHandler.handleError<String>(
          any(),
          any(),
          any(),
          defaultValue: any(named: 'defaultValue'),
        ),
      ).thenReturn(defaultLogoUrl);

      // Call the method - this should throw an exception that gets handled
      final result = await repository.getUrlByLeagueCode(leagueCode);

      // Verify the API call was made
      verify(() => mockApiService.get(leagueUrl)).called(1);

      // Verify error handler was called
      verify(
        () => mockErrorHandler.handleError<String>(
          any(),
          any(),
          any(),
          defaultValue: any(named: 'defaultValue'),
        ),
      ).called(1);

      // Verify we get the default URL
      expect(result, defaultLogoUrl);
    });
  });
}
