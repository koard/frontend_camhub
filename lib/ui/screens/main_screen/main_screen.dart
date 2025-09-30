import 'package:campusapp/ui/screens/home_screen/home_screen.dart';
import 'dart:convert';
import 'package:flutter/material.dart';

import '../profile_screen/profile_screen.dart';
import '../setting_screen/setting_screen.dart';
import '../subject_screen/take_subject_screen.dart';
import '../schedule_screen/schedule_screen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class MainHomeScreen extends StatefulWidget {
  const MainHomeScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _MainHomeScreenState createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State<MainHomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> widgetOptions = const [
    HomeScreen(),
    ScheduleScreen(),
    ProfileScreen(),
    SettingsScreen(),
    TakeSubjectScreen(),
  ];

  Future<void> _onItemTapped(int index) async {
    // Require login for protected tabs: Schedule (1) and Profile (2)
    if (index == 1 || index == 2) {
      final loggedIn = await _isLoggedIn();
      if (!loggedIn) {
        if (!mounted) return;
        final goLogin = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('ต้องเข้าสู่ระบบ'),
            content: Text(index == 1
                ? 'กรุณาเข้าสู่ระบบเพื่อดูตารางเรียน'
                : 'กรุณาเข้าสู่ระบบเพื่อดูโปรไฟล์'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('ยกเลิก'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('เข้าสู่ระบบ'),
              ),
            ],
          ),
        );
        if (goLogin == true && mounted) {
          Navigator.pushNamed(context, '/login');
        }
        return; // do not switch tab when not logged in
      }
    }

    if (!mounted) return;
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<bool> _isLoggedIn() async {
    try {
      const storage = FlutterSecureStorage();
      final tokenRaw = await storage.read(key: 'access_token');
      if (tokenRaw == null || tokenRaw.isEmpty) return false;
      try {
        final parsed = jsonDecode(tokenRaw);
        if (parsed is Map && parsed['access_token'] is String) {
          return (parsed['access_token'] as String).isNotEmpty;
        }
      } catch (_) {}
      return tokenRaw.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.amber,
        unselectedItemColor: Colors.blueGrey,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'หน้าหลัก'),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: "ตารางเรียน",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'โปรไฟล์'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
