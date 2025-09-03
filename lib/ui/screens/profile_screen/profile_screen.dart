import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:campusapp/ui/screens/account_screen/login_screen.dart';
import 'package:campusapp/ui/providers/auth_provider.dart';
import 'package:campusapp/core/routes.dart';
import '../../providers/profile_provider.dart'; // import service

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();
  late final User? _firebaseUser;

  @override
  void initState() {
    super.initState();
    _firebaseUser = FirebaseAuth.instance.currentUser;
  }

  Future<Map<String, dynamic>?> _getUserProfile() {
    if (_firebaseUser == null) return Future.value(null);
    return _userService.getUserProfile(_firebaseUser.uid);
  }

  @override
  Widget build(BuildContext context) {
    if (_firebaseUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('ข้อมูลส่วนตัว'),
          backgroundColor: const Color(0xFF113F67),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.home);
            },
          ),
        ),
        body: Center(
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
            child: const Text("เข้าสู่ระบบ เพื่อดูข้อมูลส่วนตัว"),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('ข้อมูลส่วนตัว'),
        backgroundColor: const Color(0xFF113F67),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushNamed(context, AppRoutes.home);
          },
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _getUserProfile(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final user = snapshot.data;
          if (user == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('ไม่พบข้อมูลผู้ใช้เพิ่มเติม'),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await AuthService().signout();
                      if (!mounted) return; // เช็ก mounted ก่อนใช้ context
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (route) => false,
                      );
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text("Logout"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            );
          }
          return Center(
            child: Card(
              elevation: 4,
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircleAvatar(
                      radius: 60,
                      backgroundImage: AssetImage('assets/profile_picture.png'),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      '${user['first_name']} ${user['last_name']}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.email,
                          color: Colors.blueGrey,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          user['email'],
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.blueGrey,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 32, thickness: 1.2),
                    _profileInfoRow(
                      Icons.school,
                      'ปีการศึกษา',
                      user['year'].toString(),
                    ),
                    const SizedBox(height: 10),
                    _profileInfoRow(
                      Icons.account_balance,
                      'คณะ',
                      user['faculty'],
                    ),
                    const SizedBox(height: 10),
                    _profileInfoRow(Icons.cake, 'อายุ', user['age'].toString()),
                    const SizedBox(height: 10),
                    _profileInfoRow(
                      Icons.group,
                      'เทอม',
                      user['group'].toString(),
                    ),
                    const SizedBox(height: 28),
                    ElevatedButton.icon(
                      onPressed: () async {
                        await AuthService().signout();
                        if (!mounted) return;
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          AppRoutes.home,
                          (route) => false,
                        );
                      },
                      icon: const Icon(Icons.logout),
                      label: const Text("Logout"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 14,
                        ),
                        textStyle: const TextStyle(fontSize: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _profileInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.blueGrey, size: 20),
        const SizedBox(width: 10),
        Text('$label:', style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(width: 8),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 15))),
      ],
    );
  }
}
