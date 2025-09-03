import 'package:campusapp/ui/screens/home_screen/home_screen.dart';
import 'package:flutter/material.dart';

import '../profile_screen/profile_screen.dart';
import '../setting_screen/setting_screen.dart';
import '../subject_screen/take_subject_screen.dart';
import '../schedule_screen/schedule_screen.dart';

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

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
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
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'ตั้งค่า'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
