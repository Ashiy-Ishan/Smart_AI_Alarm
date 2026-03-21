import 'package:alarm_frontend/screens/verify_account_screen.dart';
import 'package:alarm_frontend/utils/app_colors.dart';
import 'package:alarm_frontend/screens/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Alarm App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.background,
        useMaterial3: true,
        textTheme: GoogleFonts.lexendDecaTextTheme(),
      ),
      home: VerifyAccountScreen(),
    );
  }
}
