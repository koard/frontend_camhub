import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:campusapp/ui/screens/account_screen/login_screen.dart';
import '../main_screen/main_screen.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> pages = [
    {
      'title': 'ยินดีต้อนรับ',
      'subtitle':
          'เตรียมพร้อมสู่การใช้ชีวิตในรั้วมหาวิทยาลัยอย่างมั่นใจ ด้วยแอปเดียวที่ช่วยให้คุณไม่พลาดทุกเรื่องสำคัญ',
      'image':
          'https://file.aiquickdraw.com/imgcompressed/img/compressed_aef897d3a1a6dd9c4df2fed767a217c4.webp',
    },
    {
      'title': 'รวมทุกอย่างไว้ในที่เดียว',
      'subtitle':
          'ไม่ว่าจะเป็นตารางเรียน กิจกรรม ข่าวสาร หรือเอกสาร ทุกอย่างถูกรวบรวมไว้ให้คุณใช้งานได้ง่าย ๆ',
      'image':
          'https://file.aiquickdraw.com/imgcompressed/img/compressed_75a84113e2636bbc78bf8073a4909bea.webp',
    },
    {
      'title': 'วางแผนชีวิตง่ายขึ้น',
      'subtitle':
          'ตั้งเป้าหมาย ติดตามความก้าวหน้า จัดการเวลา และสร้างสมดุลระหว่างเรียนและชีวิตส่วนตัว',
      'image':
          'https://file.aiquickdraw.com/imgcompressed/img/compressed_6ee5a45c92302edeb73568b000d2ced6.webp',
    },
    {
      'title': 'พร้อมเริ่มต้นหรือยัง ?',
      'subtitle':
          'เพียงไม่กี่คลิก คุณก็พร้อมใช้งานแอปที่จะช่วยให้ชีวิตในมหาวิทยาลัยของคุณง่ายขึ้นกว่าเดิม',
      'image':
          'https://file.aiquickdraw.com/imgcompressed/img/compressed_f747977b86558a0ffb7440f53affccaf.webp',
    },
  ];

  void _nextPage() {
    if (_currentPage < pages.length - 1) {
      _controller.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.ease,
      );
    } else {
      _goToHome();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _controller.animateToPage(
        _currentPage - 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.ease,
      );
    }
  }

  void _goToHome() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seenOnboarding', true);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => MainHomeScreen()),
    );
  }

  void _goToLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF113F67), // สีพื้นหลัง
      body: PageView.builder(
        controller: _controller,
        itemCount: pages.length,
        onPageChanged: (index) => setState(() => _currentPage = index),
        itemBuilder: (context, index) {
          final page = pages[index];
          final bool showButtons = index == pages.length - 1;
          return Padding(
            padding: EdgeInsets.all(40.w), // ปรับด้วย screenutil
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (page['image'] != null)
                  SizedBox(
                    height: 250.h, // ปรับความสูง
                    child: Image.network(page['image']!, fit: BoxFit.contain),
                  ),
                SizedBox(height: 40.h), // spacing
                Text(
                  page['title']!,
                  style: TextStyle(
                    fontSize: 24.sp, // font size responsive
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 20.h),
                Text(
                  page['subtitle']!,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: Colors.white.withOpacity(0.70),
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 40.h),
                if (showButtons)
                  Column(
                    children: [
                      ElevatedButton(
                        onPressed: _goToHome,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF34699A),
                          foregroundColor: Colors.white,
                          minimumSize: Size(280.w, 45.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        child: const Text(
                          'เริ่มต้นใช้งาน',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      SizedBox(height: 12.h),
                      ElevatedButton(
                        onPressed: _goToLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD9EAFF),
                          foregroundColor: const Color(0xFF113F67),
                          minimumSize: Size(280.w, 45.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        child: const Text(
                          'เข้าสู่ระบบ',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
      bottomSheet: Container(
        height: 80.h,
        color: const Color(0xFF113F67),
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: Row(
          children: [
            SizedBox(
              width: 80.w,
              child:
                  _currentPage == 0
                      ? const SizedBox.shrink()
                      : TextButton(
                        onPressed: _previousPage,
                        style: ButtonStyle(
                          splashFactory: NoSplash.splashFactory,
                          shadowColor: WidgetStateProperty.all(
                            Colors.transparent,
                          ),
                        ),
                        child: Text(
                          'ก่อนหน้า',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12.sp,
                          ),
                        ),
                      ),
            ),
            Expanded(
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    pages.length,
                    (indexDot) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: EdgeInsets.symmetric(horizontal: 4.w),
                      width: _currentPage == indexDot ? 14.w : 6.w,
                      height: 8.h,
                      decoration: BoxDecoration(
                        color:
                            _currentPage == indexDot
                                ? Colors.white
                                : Colors.white.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 80.w,
              child: IconButton(
                onPressed: _nextPage,
                style: ButtonStyle(
                  splashFactory: NoSplash.splashFactory,
                  shadowColor: WidgetStateProperty.all(Colors.transparent),
                ),
                icon: const Icon(Icons.arrow_forward, color: Colors.white),
                iconSize: 18.sp,
                tooltip: 'Next',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
