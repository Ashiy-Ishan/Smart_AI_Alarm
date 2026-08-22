class HabitDay {
  final String? date;
  final double actualBufferMinutes;
  final double aiBufferMinutes;
  final double differenceMinutes;
  final int snoozeCount;
  final int success;

  const HabitDay({
    this.date,
    required this.actualBufferMinutes,
    required this.aiBufferMinutes,
    required this.differenceMinutes,
    required this.snoozeCount,
    required this.success,
  });

  factory HabitDay.fromJson(Map<String, dynamic> json) {
    return HabitDay(
      date: json['date']?.toString(),
      actualBufferMinutes:
          (json['actual_buffer_minutes'] as num?)?.toDouble() ?? 0.0,
      aiBufferMinutes: (json['ai_buffer_minutes'] as num?)?.toDouble() ?? 0.0,
      differenceMinutes:
          (json['difference_minutes'] as num?)?.toDouble() ?? 0.0,
      snoozeCount: (json['snooze_count'] as num?)?.toInt() ?? 0,
      success: (json['success'] as num?)?.toInt() ?? 0,
    );
  }
}

class HabitInsightModel {
  final bool available;
  final int sampleCount;
  final double? averageActualBuffer;
  final double? averageAiBuffer;
  final double? averageErrorMinutes;
  final double? averageSnooze;
  final double? successRate;
  final String trend;
  final String? message;
  final List<HabitDay> daily;

  const HabitInsightModel({
    required this.available,
    required this.sampleCount,
    this.averageActualBuffer,
    this.averageAiBuffer,
    this.averageErrorMinutes,
    this.averageSnooze,
    this.successRate,
    required this.trend,
    this.message,
    required this.daily,
  });

  factory HabitInsightModel.fromJson(Map<String, dynamic> json) {
    return HabitInsightModel(
      available: json['available'] == true,
      sampleCount: (json['sample_count'] as num?)?.toInt() ?? 0,
      averageActualBuffer: (json['average_actual_buffer'] as num?)?.toDouble(),
      averageAiBuffer: (json['average_ai_buffer'] as num?)?.toDouble(),
      averageErrorMinutes: (json['average_error_minutes'] as num?)?.toDouble(),
      averageSnooze: (json['average_snooze'] as num?)?.toDouble(),
      successRate: (json['success_rate'] as num?)?.toDouble(),
      trend: json['trend']?.toString() ?? 'not_enough_data',
      message: json['message']?.toString(),
      daily: (json['daily'] as List? ?? [])
          .map((item) => HabitDay.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
    );
  }
}
