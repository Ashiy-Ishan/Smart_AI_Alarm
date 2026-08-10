class TodayActivityModel {
  final bool available;

  final double? roomTemperature;
  final double? humidity;

  final bool motionDetected;

  final String? lightLevel;

  final int motionEvents;

  final double movementMinutes;

  final int? steps;
  final double? calories;

  final DateTime? latestReadingAt;

  final String? message;

  const TodayActivityModel({
    required this.available,
    this.roomTemperature,
    this.humidity,
    required this.motionDetected,
    this.lightLevel,
    required this.motionEvents,
    required this.movementMinutes,
    this.steps,
    this.calories,
    this.latestReadingAt,
    this.message,
  });

  factory TodayActivityModel.fromJson(Map<String, dynamic> json) {
    return TodayActivityModel(
      available: json['available'] == true,

      roomTemperature: (json['room_temperature'] as num?)?.toDouble(),

      humidity: (json['humidity'] as num?)?.toDouble(),

      motionDetected:
          json['motion_detected'] == true || json['motion_detected'] == 1,

      lightLevel: json['light_level']?.toString(),

      motionEvents: (json['motion_events'] as num?)?.toInt() ?? 0,

      movementMinutes: (json['movement_minutes'] as num?)?.toDouble() ?? 0.0,

      steps: (json['steps'] as num?)?.toInt(),

      calories: (json['calories'] as num?)?.toDouble(),

      latestReadingAt: json['latest_reading_at'] == null
          ? null
          : DateTime.tryParse(json['latest_reading_at'].toString()),

      message: json['message']?.toString(),
    );
  }
}

class TodaySleepModel {
  final bool available;

  final double? durationHours;
  final double? sleepScore;

  final int? awakenings;

  final DateTime? sleepStart;
  final DateTime? sleepEnd;

  final String? message;

  const TodaySleepModel({
    required this.available,
    this.durationHours,
    this.sleepScore,
    this.awakenings,
    this.sleepStart,
    this.sleepEnd,
    this.message,
  });

  factory TodaySleepModel.fromJson(Map<String, dynamic> json) {
    return TodaySleepModel(
      available: json['available'] == true,

      durationHours: (json['duration_hours'] as num?)?.toDouble(),

      sleepScore: (json['sleep_score'] as num?)?.toDouble(),

      awakenings: (json['awakenings'] as num?)?.toInt(),

      sleepStart: json['sleep_start'] == null
          ? null
          : DateTime.tryParse(json['sleep_start'].toString()),

      sleepEnd: json['sleep_end'] == null
          ? null
          : DateTime.tryParse(json['sleep_end'].toString()),

      message: json['message']?.toString(),
    );
  }
}

class TodayAlarmSummaryModel {
  final int completed;
  final int snoozes;

  final double? successRate;
  final double? averageUnlockDelay;

  const TodayAlarmSummaryModel({
    required this.completed,
    required this.snoozes,
    this.successRate,
    this.averageUnlockDelay,
  });

  factory TodayAlarmSummaryModel.fromJson(Map<String, dynamic> json) {
    return TodayAlarmSummaryModel(
      completed: (json['completed'] as num?)?.toInt() ?? 0,

      snoozes: (json['snoozes'] as num?)?.toInt() ?? 0,

      successRate: (json['success_rate'] as num?)?.toDouble(),

      averageUnlockDelay: (json['average_unlock_delay'] as num?)?.toDouble(),
    );
  }
}

class TodayAiModel {
  final bool trained;

  final double? accuracyScore;

  final int sampleCount;

  const TodayAiModel({
    required this.trained,
    this.accuracyScore,
    required this.sampleCount,
  });

  factory TodayAiModel.fromJson(Map<String, dynamic> json) {
    return TodayAiModel(
      trained: json['trained'] == true,

      accuracyScore: (json['accuracy_score'] as num?)?.toDouble(),

      sampleCount: (json['sample_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class TodaySummaryModel {
  final String userId;
  final String date;

  final DateTime? generatedAt;

  final TodayActivityModel activity;
  final TodaySleepModel sleep;
  final TodayAlarmSummaryModel alarms;
  final TodayAiModel ai;

  final String healthInsight;

  const TodaySummaryModel({
    required this.userId,
    required this.date,
    this.generatedAt,
    required this.activity,
    required this.sleep,
    required this.alarms,
    required this.ai,
    required this.healthInsight,
  });

  factory TodaySummaryModel.fromJson(Map<String, dynamic> json) {
    return TodaySummaryModel(
      userId: json['user_id']?.toString() ?? '',

      date: json['date']?.toString() ?? '',

      generatedAt: json['generated_at'] == null
          ? null
          : DateTime.tryParse(json['generated_at'].toString()),

      activity: TodayActivityModel.fromJson(
        Map<String, dynamic>.from(json['activity'] ?? {}),
      ),

      sleep: TodaySleepModel.fromJson(
        Map<String, dynamic>.from(json['sleep'] ?? {}),
      ),

      alarms: TodayAlarmSummaryModel.fromJson(
        Map<String, dynamic>.from(json['alarms'] ?? {}),
      ),

      ai: TodayAiModel.fromJson(Map<String, dynamic>.from(json['ai'] ?? {})),

      healthInsight:
          json['health_insight']?.toString() ??
          'No health insight available yet.',
    );
  }
}
