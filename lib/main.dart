import 'package:flutter/material.dart';
import 'constants/theme.dart';
import 'presentation/views/splash_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NexDrive',
      theme: AppTheme.lightTheme,
      home: SplashScreen(), // Start with Splash Screen
    );
  }
}
