import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:alarm_frontend/models/model_accuracy.dart';
import 'package:alarm_frontend/models/insight_data_model.dart';

class ApiService {
  static const String baseUrl =
      'http://192.168.8.186:5001/'
      'smart-ai-alarm-2f71d/'
      'us-central1/'
      'api';

  static Future<Map<String, dynamic>> checkHealth() async {
    final response = await http.get(Uri.parse('$baseUrl/health'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception('Backend error: ${response.statusCode}');
  }

  static Future<dynamic> get(String endpoint) async {
    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    }

    throw Exception('Backend error: ${response.statusCode} ${response.body}');
  }

  static Future<dynamic> post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    }

    throw Exception('Backend error: ${response.statusCode} ${response.body}');
  }

  static Future<ModelAccuracy> getModelAccuracy(String userId) async {
    final data = await get('/alarms/$userId/accuracy');

    return ModelAccuracy.fromJson(Map<String, dynamic>.from(data));
  }

  static Future<ModelAccuracy> retrainModel(String userId) async {
    final data = await post('/alarms/$userId/retrain', {});

    return ModelAccuracy.fromJson(Map<String, dynamic>.from(data));
  }

  static Future<InsightDataModel> getInsights(
    String userId, {
    int days = 7,
  }) async {
    final data = await get('/insights/$userId?days=$days');

    return InsightDataModel.fromJson(Map<String, dynamic>.from(data));
  }
}
