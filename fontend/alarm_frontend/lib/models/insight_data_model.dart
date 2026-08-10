import 'package:alarm_frontend/models/sleep_insight_model.dart';
import 'package:alarm_frontend/models/habit_insight_model.dart';
import 'package:alarm_frontend/models/model_accuracy.dart';

class InsightDataModel {
  final String userId;
  final int periodDays;

  final SleepInsightModel sleep;
  final HabitInsightModel habit;
  final ModelAccuracy accuracy;

  const InsightDataModel({
    required this.userId,
    required this.periodDays,
    required this.sleep,
    required this.habit,
    required this.accuracy,
  });

  factory InsightDataModel.fromJson(Map<String, dynamic> json) {
    return InsightDataModel(
      userId: json['user_id']?.toString() ?? '',
      periodDays: (json['period_days'] as num?)?.toInt() ?? 7,

      sleep: SleepInsightModel.fromJson(
        Map<String, dynamic>.from(json['sleep'] ?? {}),
      ),

      habit: HabitInsightModel.fromJson(
        Map<String, dynamic>.from(json['habit'] ?? {}),
      ),

      accuracy: ModelAccuracy.fromJson(
        Map<String, dynamic>.from(json['accuracy'] ?? {}),
      ),
    );
  }
}
