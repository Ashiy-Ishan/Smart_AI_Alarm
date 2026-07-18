import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';


class WeatherService {
  final String apiKey = dotenv.get('WEATHER_API', fallback: '');

  Future<Map<String, dynamic>?> fetchWeather() async {
    try {
      print("Starting weather fetch...");
      // 1. Check & Request Location Permissions
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print("Location services are disabled.");
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      print("Initial permission status: $permission");
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print("Location permissions are denied.");
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print("Location permissions are permanently denied.");
        return null;
      }

      // 2. Get Current Position
      print("Getting current position...");
      Position? position = await Geolocator.getLastKnownPosition();
      
      if (position == null) {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
        );
      }
      print("Position found: ${position.latitude}, ${position.longitude}");

      // 3. Fetch Data from OpenWeatherMap
      if (apiKey.isEmpty) {
        print("Weather API Key is empty! Check your .env file.");
        return null;
      }
      
      final url = Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather?lat=${position.latitude}&lon=${position.longitude}&appid=$apiKey&units=imperial',
      );
      print("Requesting weather from: $url");

      final response = await http.get(url);
      print("Weather response code: ${response.statusCode}");
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print("Weather data received: ${data['main']['temp']}°F");
        return data;
      } else {
        print("Weather API error: ${response.body}");
      }
    } catch (e) {
      print("Error fetching weather: $e");
    }
    return null;
  }
}
