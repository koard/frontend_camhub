import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:campusapp/core/routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    final prefs = await SharedPreferences.getInstance();
    final seenOnboarding =
        prefs.getBool('seenOnboarding') != null ? true : false;
    // หน่วงเวลา 3 วินาที
    await Future.delayed(const Duration(seconds: 3));

    if (mounted) {
      // if (seenOnboarding) {
      //   Navigator.pushNamed(context, AppRoutes.home);
      // } else {
      Navigator.pushNamed(context, AppRoutes.onboarding);
      // }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: const Color(0xFF113F67),
      body: Center(
        child: Text(
          'CampusApp',
          style: TextStyle(
            fontSize: 32,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
