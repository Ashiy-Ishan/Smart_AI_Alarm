import 'package:flutter/material.dart';

class MessageNotificationModel {
  final IconData icon;
  final String label;
  final String message;

  const MessageNotificationModel({
    required this.icon,
    required this.label,
    required this.message,
  });
}