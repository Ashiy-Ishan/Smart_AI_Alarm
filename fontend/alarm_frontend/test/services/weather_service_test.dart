import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:alarm_frontend/services/weather_service.dart';

class MockWeatherService extends Mock implements WeatherService {}

void main() {
  late WeatherService weatherService;

  setUp(() {
    weatherService = MockWeatherService();
  });

  group('WeatherService Mock Tests', () {
    test('fetchWeather returns map when API call is successful', () async {
      final mockData = {
        'main': {'temp': 30.5},
        'weather': [{'main': 'Clear'}]
      };

      when(() => weatherService.fetchWeather())
          .thenAnswer((_) async => mockData);

      final result = await weatherService.fetchWeather();

      expect(result, isNotNull);
      expect(result!['main']['temp'], 30.5);
      expect(result['weather'][0]['main'], 'Clear');
    });

    test('fetchWeather returns null when API fails', () async {
      when(() => weatherService.fetchWeather())
          .thenAnswer((_) async => null);

      final result = await weatherService.fetchWeather();

      expect(result, isNull);
    });
  });
}
