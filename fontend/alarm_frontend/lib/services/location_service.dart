import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';

// Helper model to replace Google's Prediction model
class LocationSuggestion {
  final String label;
  final String? city;
  final String? county;
  final String? state;
  final String? country;
  final double lat;
  final double lon;

  LocationSuggestion({
    required this.label,
    this.city,
    this.county,
    this.state,
    this.country,
    required this.lat,
    required this.lon,
  });

  factory LocationSuggestion.fromJson(Map<String, dynamic> json) {
    final props = json['properties'];
    return LocationSuggestion(
      label: props['formatted'] ?? "",
      city: props['city'],
      county: props['county'],
      state: props['state'],
      country: props['country'],
      lat: props['lat'].toDouble(),
      lon: props['lon'].toDouble(),
    );
  }
}

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  // Using Geoapify API Key
  final String _apiKey = dotenv.get('GEOAPIFY_API_KEY', fallback: '');

  // Fetch address suggestions from Geoapify
  Future<List<LocationSuggestion>> getSuggestions(String query) async {
    if (query.isEmpty) return [];
    
    // type=city,amenity,address to focus on specific regions and villages
    final url = Uri.parse(
      'https://api.geoapify.com/v1/geocode/autocomplete?'
      'text=$query'
      '&apiKey=$_apiKey'
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List features = data['features'] ?? [];
        return features.map((f) => LocationSuggestion.fromJson(f)).toList();
      }
    } catch (e) {
      print("Geoapify Autocomplete Error: $e");
    }
    return [];
  }

  // Reverse Geocoding using Geoapify
  Future<Map<String, dynamic>?> getCurrentLocationInfo() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      final url = Uri.parse(
        'https://api.geoapify.com/v1/geocode/reverse?'
        'lat=${position.latitude}&lon=${position.longitude}'
        '&apiKey=$_apiKey'
      );

      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['features'] != null && data['features'].isNotEmpty) {
          final props = data['features'][0]['properties'];
          return {
            'address': props['formatted'] ?? "Current Location",
            'lat': position.latitude,
            'lng': position.longitude,
          };
        }
      }
    } catch (e) {
      print("Geoapify Reverse Geocode Error: $e");
    }
    return null;
  }
}
