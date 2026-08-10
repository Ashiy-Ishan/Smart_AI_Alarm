class SleepDay {
  final String? date;
  final double hours;
  final double score;
  final int awakenings;

  const SleepDay({
    this.date,
    required this.hours,
    required this.score,
    required this.awakenings,
  });

  factory SleepDay.fromJson(Map<String, dynamic> json) {
    return SleepDay(
      date: json['date']?.toString(),
      hours: (json['hours'] as num?)?.toDouble() ?? 0.0,
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      awakenings: (json['awakenings'] as num?)?.toInt() ?? 0,
    );
  }
}

class SleepInsightModel {
  final bool available;
  final int sessionCount;
  final double? averageSleepHours;
  final double totalSleepHours;
  final double? averageSleepScore;
  final double? averageAwakenings;
  final String trend;
  final String? message;
  final List<SleepDay> daily;

  const SleepInsightModel({
    required this.available,
    required this.sessionCount,
    this.averageSleepHours,
    required this.totalSleepHours,
    this.averageSleepScore,
    this.averageAwakenings,
    required this.trend,
    this.message,
    required this.daily,
  });

  factory SleepInsightModel.fromJson(Map<String, dynamic> json) {
    return SleepInsightModel(
      available: json['available'] == true,
      sessionCount: (json['session_count'] as num?)?.toInt() ?? 0,
      averageSleepHours: (json['average_sleep_hours'] as num?)?.toDouble(),
      totalSleepHours: (json['total_sleep_hours'] as num?)?.toDouble() ?? 0.0,
      averageSleepScore: (json['average_sleep_score'] as num?)?.toDouble(),
      averageAwakenings: (json['average_awakenings'] as num?)?.toDouble(),
      trend: json['trend']?.toString() ?? 'not_enough_data',
      message: json['message']?.toString(),
      daily: (json['daily'] as List? ?? [])
          .map((item) => SleepDay.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
    );
  }
}
