import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:campusapp/models/announcement.dart';
import 'package:campusapp/ui/service/announcement_service.dart';
import 'package:campusapp/models/event.dart';
import 'package:campusapp/ui/service/event_service.dart';
import 'package:campusapp/ui/screens/annoucement_screen/announcement_detail_screen.dart';
import 'package:campusapp/ui/screens/events_screen/event_detail_screen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;
  // Banner images (assets)
  final List<String> _bannerImages = [
    'assets/camphub.png',
    'assets/camphub1.png',
    'assets/camphub2.png',
  ];

  int get bannerCount => _bannerImages.length;

  late Future<List<Event>> _eventFuture;

  late Future<List<Announcement>> _announcementFuture;

  @override
  void initState() {
    super.initState();
    _startAutoSlide();

    // Use file fallback so announcements can still show when offline
    _announcementFuture = AnnouncementService().getAnnouncements();
    _eventFuture = EventService.fetchLatest();
  }

  void _startAutoSlide() {
    _timer = Timer.periodic(const Duration(seconds: 3), (Timer timer) {
      if (_currentPage < bannerCount - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }

      if (mounted) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
        setState(() {}); // only for dot indicator
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<bool> _isLoggedIn() async {
    try {
      const storage = FlutterSecureStorage();
      final tokenRaw = await storage.read(key: 'access_token');
      if (tokenRaw == null || tokenRaw.isEmpty) return false;
      // support both raw string and JSON { access_token: "..." }
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

  Future<void> _onTapSubject() async {
    if (await _isLoggedIn()) {
      if (!mounted) return;
      Navigator.pushNamed(context, '/subject');
      return;
    }

    if (!mounted) return;
    final goLogin = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('ต้องเข้าสู่ระบบ'),
            content: const Text('กรุณาเข้าสู่ระบบก่อนเข้าหน้าลงทะเบียนเรียน'),
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: Text('Campus Life Hub', style: TextStyle(fontSize: 20.sp)),
        backgroundColor: const Color(0xFF113F67),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Banner Section
              SizedBox(
                height: 180.h,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: bannerCount,
                  onPageChanged: (index) {
                    setState(() => _currentPage = index);
                    _timer?.cancel();
                    _startAutoSlide(); // restart timer
                  },
                  itemBuilder: (context, index) {
                    final imgUrl = _bannerImages[index];
                    return Container(
                      margin: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 8.h,
                      ),
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16.r),
                        color: Colors.blue[200],
                      ),
                      child: Image.asset(
                        imgUrl,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (context, error, stack) => Center(
                              child: Icon(
                                Icons.broken_image,
                                color: Colors.white,
                                size: 40.sp,
                              ),
                            ),
                      ),
                    );
                  },
                ),
              ),
              // Dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  bannerCount,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: EdgeInsets.symmetric(
                      horizontal: 4.w,
                      vertical: 8.h,
                    ),
                    width: _currentPage == i ? 16.w : 8.w,
                    height: 8.h,
                    decoration: BoxDecoration(
                      color: _currentPage == i ? Colors.blue : Colors.grey[400],
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  ),
                ),
              ),

              // Announcements Section
              _buildSectionHeader("ประกาศ", '/announcements'),
              _buildAnnouncementList(),

              // Events Section
              _buildSectionHeader("กิจกรรม", '/events'),
              _buildEventList(),

              // Tools Section
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'เมนูเพิ่มเติม',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12.h,
                crossAxisSpacing: 12.w,
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                children: [
                  _buildToolButton(
                    Icons.school,
                    'ค้นหาวิชา',
                    onTap: () => Navigator.pushNamed(context, '/exampleInfo'),
                  ),
                  _buildToolButton(
                    Icons.computer,
                    'ลงทะเบียน',
                    onTap: _onTapSubject,
                  ),
                  _buildToolButton(
                    Icons.bookmarks,
                    'บุ๊กมาร์ก',
                    onTap: _onTapBookmarks,
                  ),
                  _buildToolButton(
                    Icons.map,
                    'แผนที่',
                    onTap: () => Navigator.pushNamed(context, '/map'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onTapBookmarks() async {
    if (await _isLoggedIn()) {
      if (!mounted) return;
      Navigator.pushNamed(context, '/bookmarkedAnnouncements');
      return;
    }
    if (!mounted) return;
    final goLogin = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('ต้องเข้าสู่ระบบ'),
            content: const Text('กรุณาเข้าสู่ระบบเพื่อใช้งานบุ๊กมาร์ก'),
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
  }

  // Section Header
  Widget _buildSectionHeader(String title, String route) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
              ),
              SizedBox(width: 8.w),
              Text(
                'ใหม่',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, route),
            child: Text(
              'ดูทั้งหมด',
              style: TextStyle(color: Colors.blue, fontSize: 14.sp),
            ),
          ),
        ],
      ),
    );
  }

  // Announcements list
  Widget _buildAnnouncementList() {
    return SizedBox(
      height: 130.h,
      child: FutureBuilder<List<Announcement>>(
        future: _announcementFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _buildOfflineMessage(
              message: 'คุณออฟไลน์อยู่\nไม่สามารถโหลดประกาศได้',
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildOfflineMessage(
              message: 'คุณออฟไลน์อยู่\nไม่สามารถโหลดประกาศได้',
            );
          }

          final announcements = snapshot.data!;
          return ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            itemCount: announcements.length,
            separatorBuilder: (_, __) => SizedBox(width: 12.w),
            itemBuilder: (context, index) {
              final announcement = announcements[index];
              return _buildCardAnnouncements(
                announcement.title,
                announcement.description,
                announcement.displayDate,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder:
                          (_) => AnnouncementDetailScreen(
                            announcement: announcement,
                          ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  // Events list
  Widget _buildEventList() {
    return SizedBox(
      height: 130.h,
      child: FutureBuilder<List<Event>>(
        future: _eventFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _buildOfflineMessage(
              message: 'คุณออฟไลน์อยู่\nไม่สามารถโหลดกิจกรรมได้',
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildOfflineMessage(
              message: 'คุณออฟไลน์อยู่\nไม่สามารถโหลดกิจกรรมได้',
            );
          }

          final data = snapshot.data!;
          return ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            itemCount: data.length,
            separatorBuilder: (_, __) => SizedBox(width: 12.w),
            itemBuilder: (context, index) {
              final item = data[index];
              return _buildCard(
                item.name,
                item.description,
                item.startDate,
                onTap: () {
                  final map = <String, dynamic>{
                    'id': item.id,
                    'name': item.name,
                    'description': item.description,
                    'start_date': item.startDate?.toIso8601String(),
                    'end_date': item.endDate?.toIso8601String(),
                    'image_url': item.imageUrl,
                    'location': item.location,
                  };
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => EventDetailScreen(event: map),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  // Shared card widget
  Widget _buildCard(
    String title,
    String description,
    DateTime? date, {
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12.r),
        onTap: onTap,
        child: Container(
          width: 200.w,
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4.r)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 4.h),
              Text(
                description,
                style: TextStyle(fontSize: 12.sp),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Text(
                date != null ? '${date.day}/${date.month}/${date.year}' : '',
                style: TextStyle(fontSize: 10.sp, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardAnnouncements(
    String title,
    String description,
    DateTime? date, {
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12.r),
        onTap: onTap,
        child: Container(
          width: 200.w,
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4.r)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 4.h),
              Text(
                description,
                style: TextStyle(fontSize: 12.sp),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Text(
                date != null ? '${date.day}/${date.month}/${date.year}' : '',
                style: TextStyle(fontSize: 10.sp, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Tool button
  Widget _buildToolButton(IconData icon, String label, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF113F67),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 32.sp),
            SizedBox(height: 8.h),
            Text(
              label,
              style: TextStyle(color: Colors.white, fontSize: 12.sp),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Offline message helper (no retry button)
  Widget _buildOfflineMessage({required String message}) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off, size: 40, color: Colors.grey),
            SizedBox(height: 8.h),
            Text(
              message,
              style: TextStyle(color: Colors.black54, fontSize: 13.sp),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
