import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

class WeatherService {
  final String apiKey = dotenv.get('WEATHER_API', fallback: '');

  Future<Map<String, dynamic>?> fetchWeather() async {
    try {
      debugPrint('Starting weather fetch...');
      // 1. Check & Request Location Permissions
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location services are disabled.');
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      debugPrint('Initial permission status: $permission');
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('Location permissions are denied.');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('Location permissions are permanently denied.');
        return null;
      }

      // 2. Get Current Position
      debugPrint('Getting current position...');
      final position = await Geolocator.getLastKnownPosition() ??
          await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.low,
            ),
          );
      debugPrint('Position found: ${position.latitude}, ${position.longitude}');

      // 3. Fetch Data from OpenWeatherMap
      if (apiKey.isEmpty) {
        debugPrint('Weather API key is empty; check your .env file.');
        return null;
      }
      
      final url = Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather?lat=${position.latitude}&lon=${position.longitude}&appid=$apiKey&units=imperial',
      );
      debugPrint('Requesting weather for the current location.');

      final response = await http.get(url);
      debugPrint('Weather response code: ${response.statusCode}');
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          debugPrint('Weather data received.');
          return decoded;
        }
        debugPrint('Weather API returned an unexpected response.');
      } else {
        debugPrint('Weather API returned HTTP ${response.statusCode}.');
      }
    } catch (error, stackTrace) {
      debugPrint('Error fetching weather: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
    return null;
  }
}
