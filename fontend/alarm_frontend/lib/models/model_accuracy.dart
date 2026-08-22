class ModelAccuracy {
  final bool trained;
  final String? userId;
  final int sampleCount;
  final double? accuracyScore;
  final double? mae;
  final double? rmse;
  final double? r2;

  final DateTime? trainedAt;
  final String? message;

  const ModelAccuracy({
    required this.trained,
    this.userId,
    required this.sampleCount,
    this.accuracyScore,
    this.mae,
    this.rmse,
    this.r2,
    this.trainedAt,
    this.message,
  });

  factory ModelAccuracy.fromJson(Map<String, dynamic> json) {
    return ModelAccuracy(
      trained: json['trained'] == true,

      userId: json['user_id']?.toString(),

      sampleCount: (json['sample_count'] as num?)?.toInt() ?? 0,

      accuracyScore: (json['accuracy_score'] as num?)?.toDouble(),

      mae: (json['mae'] as num?)?.toDouble(),

      rmse: (json['rmse'] as num?)?.toDouble(),

      r2: (json['r2'] as num?)?.toDouble(),

      trainedAt: json['trained_at'] == null
          ? null
          : DateTime.tryParse(json['trained_at'].toString()),

      message: json['message']?.toString(),
    );
  }
}
