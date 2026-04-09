import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import 'login_screen.dart';
import 'home_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Wait for splash animation, then route based on auth state
    Timer(const Duration(seconds: 3), () {
      _navigateBasedOnAuth();
    });
  }

  void _navigateBasedOnAuth() {
    final authState = ref.read(authProvider);
    final destination = authState.isAuthenticated ? HomeScreen() : LoginScreen();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => destination),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Image.asset(
          'assets/NexDrive.gif',
          width: 200,
          height: 200,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
