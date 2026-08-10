enum AgendaSource { googleCalendar, gmail }

class AgendaModel {
  final String id; // Unique ID for de-duplication
  final String time; // Current Time (e.g. 11:00)
  final String endTime; // e.g. 12:00
  final String title;
  final String subtitle;
  final String? originalTime; // Previous start time if changed
  final String? originalEndTime; // Previous end time
  final String? dateLabel;
  final bool isUpdated;
  final AgendaSource source;
  final DateTime dateTime;

  const AgendaModel({
    required this.id,
    required this.time,
    required this.endTime,
    required this.title,
    required this.subtitle,
    required this.source,
    required this.dateTime,
    this.originalTime,
    this.originalEndTime,
    this.dateLabel,
    this.isUpdated = false,
  });
<<<<<<< HEAD
=======

  Map<String, dynamic> toJson() => {
    'id': id,
    'time': time,
    'endTime': endTime,
    'title': title,
    'subtitle': subtitle,
    'originalTime': originalTime,
    'originalEndTime': originalEndTime,
    'dateLabel': dateLabel,
    'isUpdated': isUpdated,
    'source': source.index,
    'dateTime': dateTime.toIso8601String(),
  };

  factory AgendaModel.fromJson(Map<String, dynamic> json) => AgendaModel(
    id: json['id'] ?? json['title'],
    time: json['time'],
    endTime: json['endTime'] ?? "",
    title: json['title'],
    subtitle: json['subtitle'],
    originalTime: json['originalTime'],
    originalEndTime: json['originalEndTime'],
    dateLabel: json['dateLabel'],
    isUpdated: json['isUpdated'] ?? false,
    source: AgendaSource.values[json['source'] ?? 0],
    dateTime: DateTime.parse(json['dateTime']),
  );
>>>>>>> origin/main
}
