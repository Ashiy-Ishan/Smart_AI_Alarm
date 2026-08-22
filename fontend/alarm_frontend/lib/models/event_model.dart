class EventModel {
  final String time;
  final String title;
  final String? extra;
  final String? rightTime;
  final bool highlight;

  const EventModel({
    required this.time,
    required this.title,
    this.extra,
    this.rightTime,
    this.highlight = false,
  });
}
