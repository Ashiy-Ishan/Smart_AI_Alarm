import 'package:flutter/material.dart';

class EmailModel {
  final String name;
  final String time;
  final String preview;
  final IconData icon;
  final bool isNew;
  final bool isUrgent;

  const EmailModel({
    required this.name,
    required this.time,
    required this.preview,
    required this.icon,
    this.isNew = false,
    this.isUrgent = false,
  });

  EmailModel copyWith({
    String? name,
    String? time,
    String? preview,
    IconData? icon,
    bool? isNew,
    bool? isUrgent,
  }) {
    return EmailModel(
      name: name ?? this.name,
      time: time ?? this.time,
      preview: preview ?? this.preview,
      icon: icon ?? this.icon,
      isNew: isNew ?? this.isNew,
      isUrgent: isUrgent ?? this.isUrgent,
    );
  }
}