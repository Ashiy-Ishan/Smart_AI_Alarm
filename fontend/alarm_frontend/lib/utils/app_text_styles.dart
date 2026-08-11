import 'package:flutter/material.dart';

class AppTextStyles {
  static const TextStyle heading = TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle subHeading = TextStyle(fontSize: 14);

  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.black,
  );

  static const TextStyle link = TextStyle(
    fontSize: 14,
    color: Color(0xFFD9B56D), // Keep gold for links
    fontWeight: FontWeight.w500,
  );

  static const TextStyle label = TextStyle(fontSize: 14);
}
