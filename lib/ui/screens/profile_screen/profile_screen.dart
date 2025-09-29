import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:campusapp/ui/screens/account_screen/login_screen.dart';
import 'package:campusapp/core/routes.dart';
import 'package:campusapp/ui/service/profile_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flip_card/flip_card.dart';
import 'package:campusapp/ui/screens/main_screen/main_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';
import 'dart:io';
import 'package:campusapp/ui/service/schedule_services.dart';
import 'package:campusapp/ui/service/announcement_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();
  final _storage = const FlutterSecureStorage();
  final ImagePicker _picker = ImagePicker();
  late Future<Map<String, dynamic>?> _futureProfile;
  bool _isUploading = false;

  MediaType? _mediaTypeFromMime(String? mimeType) {
    if (mimeType == null) return null;
    final parts = mimeType.split('/');
    if (parts.length != 2) return null;
    if (parts.first != 'image') return null;
    final subtype = parts.last.toLowerCase();

    switch (subtype) {
      case 'jpeg':
      case 'jpg':
        return MediaType('image', 'jpeg');
      case 'png':
        return MediaType('image', 'png');
      default:
        return null;
    }
  }

  MediaType? _mediaTypeFromPath(String path) {
    final lowerPath = path.toLowerCase();
    if (lowerPath.endsWith('.jpg') || lowerPath.endsWith('.jpeg')) {
      return MediaType('image', 'jpeg');
    } else if (lowerPath.endsWith('.png')) {
      return MediaType('image', 'png');
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _futureProfile = _userService.getUserProfile();
  }

  Future<void> _pickAndUploadImage() async {
    final ImageSource? source = await showDialog<ImageSource>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('เลือกรูปภาพ'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('ถ่ายรูป'),
                  onTap: () => Navigator.of(context).pop(ImageSource.camera),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('เลือกจากคลัง'),
                  onTap: () => Navigator.of(context).pop(ImageSource.gallery),
                ),
              ],
            ),
          ),
    );

    if (source == null) return;

    final XFile? image = await _picker.pickImage(
      source: source,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _isUploading = true;
      });

      try {
  final mimeType = image.mimeType;
        MediaType? mediaType = _mediaTypeFromMime(mimeType);
        mediaType ??= _mediaTypeFromPath(image.path);

        if (mediaType == null) {
          setState(() {
            _isUploading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'กรุณาเลือกรูปภาพในรูปแบบ JPEG, PNG, GIF หรือ WebP เท่านั้น',
              ),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        final success = await _userService.uploadProfileImage(
          File(image.path),
          contentType: mediaType,
        );

        if (success) {
          // รีเฟรชข้อมูลโปรไฟล์
          setState(() {
            _futureProfile = _userService.getUserProfile();
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('อัพโหลดรูปโปรไฟล์สำเร็จ'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('เกิดข้อผิดพลาดในการอัพโหลดรูป'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  Widget _buildProfileImage(String? profileImageUrl) {
    final baseUrl =
        dotenv.env['API_BASE_URL']?.trim().replaceAll(RegExp(r"/+$"), '') ??
        'http://localhost:8000';

    ImageProvider backgroundImage;
    if (profileImageUrl != null && profileImageUrl.isNotEmpty) {
      backgroundImage = NetworkImage('$baseUrl$profileImageUrl');
    } else {
      backgroundImage = const AssetImage('assets/profile_picture.png');
    }

    return Stack(
      children: [
        CircleAvatar(
          radius: 60,
          backgroundImage: backgroundImage,
          child:
              _isUploading
                  ? const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  )
                  : null,
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: _isUploading ? null : _pickAndUploadImage,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(
                Icons.camera_alt,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
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
        future: _futureProfile,
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
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                      );
                    },
                    child: const Text('เข้าสู่ระบบ เพื่อดูข้อมูลส่วนตัว'),
                  ),
                ],
              ),
            );
          }
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FlipCard(
                direction: FlipDirection.HORIZONTAL, // หรือ VERTICAL
                front: Card(
                  color: const Color(0xFF113F67),
                  elevation: 4,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
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
                        _buildProfileImage(user['profile_image_url']),
                        const SizedBox(height: 20),
                        Text(
                          '${user['fullname'] ?? 'ไม่มีชื่อ'}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.email,
                              color: Colors.white,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              user['email'] ?? 'ไม่มีอีเมล',
                              style: const TextStyle(
                                fontSize: 15,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          "แตะเพื่อดูรายละเอียดเพิ่มเติม",
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),

                back: Card(
                  color: const Color(0xFF113F67),
                  elevation: 4,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
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
                        _profileInfoRow(
                          Icons.badge,
                          'ไอดีผู้ใช้',
                          user['id'].toString(),
                        ),
                        const SizedBox(height: 10),
                        _profileInfoRow(
                          Icons.person,
                          'ชื่อผู้ใช้',
                          user['fullname'] ?? '',
                        ),
                        const SizedBox(height: 10),
                        _profileInfoRow(
                          Icons.cake,
                          'อายุ',
                          (user['age'] ?? 0).toString(),
                        ),
                        const SizedBox(height: 10),
                        _profileInfoRow(
                          Icons.account_balance,
                          'คณะ (ID)',
                          (user['faculty_name'] ?? '').toString(),
                        ),
                        const SizedBox(height: 10),
                        _profileInfoRow(
                          Icons.school,
                          'ปีการศึกษา',
                          (user['year_of_study'] ?? '').toString(),
                        ),
                        const SizedBox(height: 28),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () async {
                  await _storage.delete(key: 'access_token');
                  // ล้างไฟล์ cache ตารางเรียน และประกาศ (รวมถึง bookmark)
                  try {
                    await ScheduleCourseService().clearScheduleFileCache();
                    await AnnouncementService()
                        .clearAllCaches(); // ล้าง cache ทั้งหมด รวม bookmark
                  } catch (_) {}
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => MainHomeScreen()),
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
          );
        },
      ),
    );
  }

  Widget _profileInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(width: 10),
        Text(
          '$label:',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 15, color: Colors.white),
          ),
        ),
      ],
    );
  }
}
